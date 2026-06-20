import SwiftUI
import Combine

/// Én spickseddel-post pr. sygdom.
struct CheatEntry: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let chapter: String
    let high: Bool
    var body: String
}

/// Indlæser spickseddel-poster fra cheatsheet.json og overlejrer brugerens
/// egne rettelser (gemt lokalt i Dokumenter).
final class CheatStore: ObservableObject {
    @Published var entries: [CheatEntry] = []

    private var editURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("cheat_edits.json")
    }

    init() { load() }

    func load() {
        var defaults: [CheatEntry] = []
        if let url = Bundle.main.url(forResource: "cheatsheet", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([CheatEntry].self, from: data) {
            defaults = decoded
        }
        let edits = loadEdits()
        entries = defaults.map { e in
            var e2 = e
            if let edited = edits[e.id] { e2.body = edited }
            return e2
        }
    }

    func body(for id: String) -> String { entries.first { $0.id == id }?.body ?? "" }

    func update(id: String, body: String) {
        guard let i = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[i].body = body
        var edits = loadEdits()
        edits[id] = body
        if let d = try? JSONEncoder().encode(edits) { try? d.write(to: editURL) }
    }

    func resetAll() {
        try? FileManager.default.removeItem(at: editURL)
        load()
    }

    private func loadEdits() -> [String: String] {
        guard let data = try? Data(contentsOf: editURL),
              let dec = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return dec
    }

    /// Hele spickseddlen samlet som markdown (til "Hent").
    var fullMarkdown: String {
        var out = "# 🩺 Spickseddel – alle pensum-sygdomme\n"
        var lastCh = ""
        for e in entries {
            if e.chapter != lastCh { out += "\n## \(e.chapter)\n"; lastCh = e.chapter }
            out += "\n### \(e.name)\(e.high ? " ⭐" : "")\n\(e.body)\n"
        }
        return out
    }
}

private let cheatChapterOrder = [
    "Hjerte-kar-sygdomme", "Lungesygdomme", "Nyre- og urinvejssygdomme",
    "Neurologiske sygdomme", "Endokrine sygdomme", "Blodsygdomme",
    "Bevægeapparatets sygdomme", "Mave-Tarm-sygdomme", "Psykiske sygdomme",
    "Allergiske sygdomme", "Gynækologiske sygdomme og obstetrik",
    "Kræftsygdomme", "Infektionssygdomme",
]

struct CheatSheetView: View {
    @StateObject private var store = CheatStore()
    @State private var search = ""
    @State private var exportURL: URL?

    private var grouped: [String: [CheatEntry]] {
        let f = search.isEmpty ? store.entries : store.entries.filter {
            $0.name.localizedCaseInsensitiveContains(search) || $0.chapter.localizedCaseInsensitiveContains(search)
        }
        return Dictionary(grouping: f, by: { $0.chapter })
    }

    private func chapterRank(_ c: String) -> Int {
        cheatChapterOrder.firstIndex(of: c) ?? 99
    }

    var body: some View {
        #if os(macOS)
        content
        #else
        NavigationView { content }
        #endif
    }

    private var content: some View {
        List {
            ForEach(grouped.keys.sorted { chapterRank($0) < chapterRank($1) }, id: \.self) { ch in
                Section(header: Text(ch)) {
                    ForEach(grouped[ch] ?? []) { entry in
                        NavigationLink(destination: CheatDetailView(entry: entry, store: store)) {
                            HStack {
                                Text(entry.name).font(.headline)
                                Spacer()
                                if entry.high {
                                    Image(systemName: "star.fill")
                                        .font(.caption).foregroundColor(.orange)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Spickseddel")
        .searchable(text: $search, prompt: "Søg efter sygdom eller kapitel")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let url = exportURL {
                    ShareLink(item: url) { Label("Hent", systemImage: "square.and.arrow.down") }
                }
            }
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button(role: .destructive) { store.resetAll() } label: {
                        Label("Nulstil alle ændringer", systemImage: "arrow.counterclockwise")
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .onAppear(perform: writeExport)
    }

    private func writeExport() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SPICKSEDDEL.md")
        try? store.fullMarkdown.write(to: url, atomically: true, encoding: .utf8)
        exportURL = url
    }
}

/// Detalje for én sygdom — pænt opsat, med "Rediger"-knap.
struct CheatDetailView: View {
    let entry: CheatEntry
    @ObservedObject var store: CheatStore
    @State private var editing = false
    @State private var draft = ""

    var body: some View {
        ScrollView {
            if editing {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rediger (markdown — fx **fed**)")
                        .font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $draft)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 360)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                }
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    if entry.high {
                        Label("Høj prioritet", systemImage: "star.fill")
                            .font(.caption).bold().foregroundColor(.orange)
                    }
                    ForEach(bodyLines, id: \.self) { line in
                        Text(.init(line))
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .navigationTitle(entry.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if editing {
                    Button("Gem") {
                        store.update(id: entry.id, body: draft)
                        editing = false
                    }
                    .bold()
                } else {
                    Button {
                        draft = store.body(for: entry.id)
                        editing = true
                    } label: { Label("Rediger", systemImage: "pencil") }
                }
            }
        }
    }

    /// Linjer fra body, med "- " gjort til "• " så punktlisten ser pæn ud.
    private var bodyLines: [String] {
        store.body(for: entry.id)
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { line in
                let s = String(line)
                return s.hasPrefix("- ") ? "• \(s.dropFirst(2))" : s
            }
    }
}
