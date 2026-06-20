import SwiftUI

// MARK: - Hyppighedskategori

enum FrequencyCategory: String, CaseIterable, Identifiable {
    case megetHyppig = "Meget hyppig"
    case hyppig      = "Hyppig"
    case middel      = "Middel"
    case sjaelden    = "Sjælden"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .megetHyppig: return .red
        case .hyppig:      return .orange
        case .middel:      return .blue
        case .sjaelden:    return .secondary
        }
    }

    var icon: String {
        switch self {
        case .megetHyppig: return "chart.bar.fill"
        case .hyppig:      return "chart.bar"
        case .middel:      return "minus.circle.fill"
        case .sjaelden:    return "circle"
        }
    }

    var description: String {
        switch self {
        case .megetHyppig: return ">15 % af befolkningen eller >50.000/år"
        case .hyppig:      return "1–15 % eller 5.000–50.000/år"
        case .middel:      return "0,5–1 % eller 1.000–5.000/år"
        case .sjaelden:    return "<0,5 % eller <1.000/år"
        }
    }

    static func of(_ disease: Disease) -> FrequencyCategory {
        let t = disease.prevalence.lowercased()
        let isVeryCommon = ["ekstremt hyppig", "meget hyppig", "næsten alle", "rammer alle",
                            "30 %", "30%", "25 %", "25%", "20 %", "20%", "15-20 %", "15-20%",
                            "10-20%", "10-20 %", "ca. 20", "ca. 15"]
            .contains { t.contains($0) }
        let isCommon = ["hyppig", "5-10%", "5-8%", "ca. 10", "ca. 5", "ca. 1 %",
                        "300.000", "320.000", "500.000", "400.000", "90.000", "80.000", "60.000"]
            .contains { t.contains($0) }
        let isMiddel = ["ca. 1%", "ca. 2%", "ca. 3%", "ca. 0,5", "ca. 25.000",
                        "ca. 10.000", "ca. 8.000", "ca. 6.000", "ca. 50.000"]
            .contains { t.contains($0) }

        if isVeryCommon { return .megetHyppig }
        if isCommon     { return .hyppig }
        if isMiddel     { return .middel }
        return .sjaelden
    }
}

// MARK: - Forekomst-visning

struct PrevalenceView: View {
    let diseases: [Disease]

    enum Grouping: String, CaseIterable {
        case chapter  = "Kapitel"
        case category = "Hyppighed"
    }

    @State private var grouping: Grouping = .chapter
    @State private var searchText = ""
    @State private var selectedDisease: Disease? = nil

    private var pool: [Disease] {
        diseases.filter { !$0.isTopic }
    }

    private var filtered: [Disease] {
        guard !searchText.isEmpty else { return pool }
        return pool.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // Kapitler sorteret som de optræder i bogen (alfabetisk fallback)
    private var chapters: [String] {
        Array(Set(pool.map { $0.chapter })).sorted()
    }

    private func diseases(inChapter chapter: String) -> [Disease] {
        filtered
            .filter { $0.chapter == chapter }
            .sorted { FrequencyCategory.of($0).allCases_index < FrequencyCategory.of($1).allCases_index }
    }

    private func diseases(inCategory cat: FrequencyCategory) -> [Disease] {
        filtered
            .filter { FrequencyCategory.of($0) == cat }
            .sorted { $0.chapter == $1.chapter ? $0.name < $1.name : $0.chapter < $1.chapter }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if grouping == .chapter {
                chapterList
            } else {
                categoryList
            }
        }
        .searchable(text: $searchText, prompt: "Søg efter sygdom…")
        #if os(macOS)
        .navigationTitle("Forekomster")
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Gruppering", selection: $grouping) {
                    ForEach(Grouping.allCases, id: \.self) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }
        }
        .sheet(item: $selectedDisease) { disease in
            NavigationStack {
                DiseaseDetailView(disease: disease)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Luk") { selectedDisease = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Kapitel-grupperet

    private var chapterList: some View {
        List {
            ForEach(chapters, id: \.self) { chapter in
                let rows = diseases(inChapter: chapter)
                if !rows.isEmpty {
                    Section {
                        ForEach(rows) { disease in
                            diseaseRow(disease)
                        }
                    } header: {
                        chapterHeader(chapter, rows: rows)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }

    // MARK: - Kategori-grupperet

    private var categoryList: some View {
        List {
            ForEach(FrequencyCategory.allCases) { cat in
                let rows = diseases(inCategory: cat)
                if !rows.isEmpty {
                    Section {
                        ForEach(rows) { disease in
                            diseaseRow(disease)
                        }
                    } header: {
                        categoryHeader(cat, count: rows.count)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }

    // MARK: - Rækker og headers

    private func diseaseRow(_ disease: Disease) -> some View {
        let cat = FrequencyCategory.of(disease)
        return Button {
            selectedDisease = disease
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Farve-dot
                Circle()
                    .fill(cat.color)
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 3) {
                    Text(disease.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(prevalenceSnippet(disease.prevalence))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    private func chapterHeader(_ chapter: String, rows: [Disease]) -> some View {
        let cats = rows.map { FrequencyCategory.of($0) }
        let dominantColor: Color = cats.first?.color ?? .secondary
        return HStack(spacing: 6) {
            Image(systemName: rows.first?.chapterIcon ?? "book")
                .foregroundColor(dominantColor)
            Text(chapter)
                .font(.subheadline.bold())
            Spacer()
            Text("\(rows.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func categoryHeader(_ cat: FrequencyCategory, count: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: cat.icon)
                .foregroundColor(cat.color)
            VStack(alignment: .leading, spacing: 1) {
                Text(cat.rawValue)
                    .font(.subheadline.bold())
                    .foregroundColor(cat.color)
                Text(cat.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(count)")
                .font(.caption.bold())
                .foregroundColor(cat.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(cat.color.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    // MARK: - Hjælper

    private func prevalenceSnippet(_ text: String) -> String {
        // Tag tekst til første rigtige sætningsafslutning (ikke forkortelser)
        var result = ""
        var i = text.startIndex
        while i < text.endIndex {
            let ch = text[i]
            result.append(ch)
            if ch == "." {
                let next = text.index(after: i)
                // Stop kun hvis næste tegn er mellemrum + stort bogstav (ny sætning)
                if next < text.endIndex, text[next] == " " {
                    let afterSpace = text.index(after: next)
                    if afterSpace < text.endIndex, text[afterSpace].isUppercase {
                        break
                    }
                }
            }
            i = text.index(after: i)
            if result.count >= 110 { result += "…"; break }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }
}

// Hjælper til sortering
private extension FrequencyCategory {
    var allCases_index: Int {
        FrequencyCategory.allCases.firstIndex(of: self) ?? 99
    }
}
