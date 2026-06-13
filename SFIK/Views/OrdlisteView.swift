import SwiftUI

/// Et opslag i begrebsordlisten (fagterm → forklaring).
struct GlossaryTerm: Codable, Identifiable, Hashable {
    let term: String
    let definition: String
    var id: String { term }
}

struct OrdlisteView: View {
    @State private var terms: [GlossaryTerm] = []
    @State private var searchText = ""

    private var filtered: [GlossaryTerm] {
        guard !searchText.isEmpty else { return terms }
        return terms.filter {
            $0.term.localizedCaseInsensitiveContains(searchText) ||
            $0.definition.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Grupperet efter forbogstav (A, B, C …).
    private var grouped: [(letter: String, items: [GlossaryTerm])] {
        let dict = Dictionary(grouping: filtered) { term -> String in
            String(term.term.prefix(1)).uppercased()
        }
        return dict.keys.sorted().map { ($0, dict[$0]!.sorted { $0.term.localizedCompare($1.term) == .orderedAscending }) }
    }

    var body: some View {
        #if os(macOS)
        content
        #else
        NavigationView {
            content
        }
        #endif
    }

    private var content: some View {
        List {
            if filtered.isEmpty {
                Text("Ingen begreber matcher \"\(searchText)\".")
                    .foregroundColor(.secondary)
            }
            ForEach(grouped, id: \.letter) { section in
                Section(header: Text(section.letter)) {
                    ForEach(section.items) { term in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(term.term)
                                .font(.headline)
                            Text(term.definition)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(InsetGroupedListStyle())
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Ordliste")
        .searchable(text: $searchText, prompt: "Søg efter begreb eller forklaring")
        .onAppear(perform: loadTerms)
    }

    private func loadTerms() {
        guard terms.isEmpty,
              let url = Bundle.main.url(forResource: "glossary", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([GlossaryTerm].self, from: data)
        else { return }
        terms = decoded
    }
}

#Preview {
    OrdlisteView()
}
