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
        case .sjaelden:    return Color(.systemGray)
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

    var threshold: String {
        switch self {
        case .megetHyppig: return ">15 % el. >50.000/år"
        case .hyppig:      return "1–15 % el. 5.000–50.000/år"
        case .middel:      return "0,5–1 % el. 1.000–5.000/år"
        case .sjaelden:    return "<0,5 % el. <1.000/år"
        }
    }

    static func of(_ disease: Disease) -> FrequencyCategory {
        let t = disease.prevalence.lowercased()
        if ["ekstremt hyppig", "meget hyppig", "næsten alle", "rammer alle",
            "30 %", "30%", "25 %", "25%", "20 %", "20%", "15-20%", "15-20 %",
            "ca. 20", "ca. 15", "ca. 17"].contains(where: { t.contains($0) }) {
            return .megetHyppig
        }
        if ["hyppig", "5-10%", "5-8%", "ca. 10", "ca. 5 %", "ca. 5-",
            "300.000", "320.000", "500.000", "400.000", "90.000",
            "80.000", "60.000", "50.000"].contains(where: { t.contains($0) }) {
            return .hyppig
        }
        if ["ca. 1%", "ca. 1 %", "ca. 2%", "ca. 2 %", "ca. 3%", "ca. 0,5",
            "ca. 25.000", "ca. 10.000", "ca. 8.000",
            "ca. 6.000", "ca. 50.000"].contains(where: { t.contains($0) }) {
            return .middel
        }
        return .sjaelden
    }
}

// MARK: - Udtrækning af køn og debutalder (kun fra pensum-tekst)

struct PrevalenceFacts {
    /// nil = ingen pensum-data fundet → chip vises ikke
    let sex:   (symbol: String, label: String)?
    let debut: String?

    static func from(_ raw: String) -> PrevalenceFacts {
        let t = raw.lowercased()
        return PrevalenceFacts(sex: extractSex(t), debut: extractDebut(t))
    }

    // MARK: Køn

    private static func extractSex(_ t: String) -> (String, String)? {
        // "kvinders:mænd ca. 2:1" eller "kvinde/mand ratio ca. 3:1"
        if let ratio = ratioAfter(t, keywords: ["kvinder:mænd", "kvinde:mand", "kvinde/mand ratio", "kvinde/mand"]) {
            return ("♀", "Kvinder \(ratio)")
        }
        // "mænd/kvinder ratio 5:1" eller "mænd:kvinder"
        if let ratio = ratioAfter(t, keywords: ["mænd/kvinder", "mænd:kvinder"]) {
            return ("♂", "Mænd \(ratio)")
        }
        // "X× hyppigere" / "Xx hyppigere" i nærheden af kvind/mænd
        // Finder ALLE multiplier-mønstre i teksten, tjekker kontekst
        let multPattern = #"(\d+(?:[-–]\d+)?)\s*[x×]\s*hyppigere"#
        var searchRange = t.startIndex..<t.endIndex
        while let mRange = t.range(of: multPattern, options: .regularExpression, range: searchRange) {
            let match = String(t[mRange])
            let contextStart = t.index(mRange.lowerBound, offsetBy: -30, limitedBy: t.startIndex) ?? t.startIndex
            let context = String(t[contextStart..<mRange.lowerBound])
            if let numStr = firstMatch(match, pattern: #"(\d+(?:[-–]\d+)?)"#) {
                let display = numStr.replacingOccurrences(of: "-", with: "–")
                if context.contains("kvind") { return ("♀", "Kvinder \(display)×") }
                if context.contains("mænd") || context.contains("drenge") { return ("♂", "Mænd \(display)×") }
            }
            guard mRange.upperBound < t.endIndex else { break }
            searchRange = mRange.upperBound..<t.endIndex
        }
        // Stærk overhyppighed kvinder med parentes-ratio
        if t.contains("stærk overhyppighed hos kvinder") {
            if let r = firstMatch(t, pattern: #"\((\d+:\d+)\)"#),
               let inner = firstMatch(r, pattern: #"\d+:\d+"#) { return ("♀", "Kvinder \(inner)") }
            return ("♀", "Næsten kun kvinder")
        }
        if t.contains("(kvinder)") { return ("♀", "Primært kvinder") }
        if t.contains("kvinder hyppigere") || t.contains("let overhyppighed hos kvinder") { return ("♀", "Kvinder let ↑") }
        if t.contains("overhyppighed hos kvinder")  { return ("♀", "Kvinder ↑") }
        if t.contains("hyppigst hos mænd") || t.contains("mænd lidt hyppigere") || t.contains("let overhyppighed hos mænd") { return ("♂", "Mænd let ↑") }
        if t.contains("drenge/mænd") { return ("♂", "Drenge/mænd ↑") }
        if t.contains("kønsratio 1:1") || t.contains("ratio 1:1") { return ("♀♂", "Ligelig 1:1") }
        return nil
    }

    // MARK: Debutalder

    private static func extractDebut(_ t: String) -> String? {
        // 1. Eksplicit aldersinterval i HELE teksten (X-Y-årsalderen / X-Y år)
        //    Scanner efter kontekst-ord der peger på debutalder
        let contextWords = ["debut", "debuterer", "debuteres", "hyppigst i", "typisk i",
                            "hyppigst hos", "rammer", "rammer typisk", "oftest i",
                            "rammer især", "hyppig i", "ses hos", "incidens", "ses primært"]
        for kw in contextWords {
            guard let kwEnd = t.range(of: kw)?.upperBound else { continue }
            let window = String(t[kwEnd...].prefix(50))
            if let r = window.range(of: #"(\d{1,2})[-–](\d{2,3})"#, options: .regularExpression) {
                let nums = String(window[r])
                let parts = nums.components(separatedBy: CharacterSet(charactersIn: "-–"))
                if let a = Int(parts[0]), let b = Int(parts.last ?? ""), a >= 5, b <= 90 {
                    // Afvis hvis efterfulgt af % (procent, ikke alder)
                    let afterNums = String(window[r.upperBound...].prefix(3))
                    guard !afterNums.hasPrefix("%") else { continue }
                    return "\(nums) år"
                }
            }
        }

        // 2. Generel aldersnævnelse i teksten (X-Y-årsalderen)
        if let m = firstMatch(t, pattern: #"(\d{1,2})[-–](\d{2,3})[-\s]*årsalderen"#) {
            if let r = m.range(of: #"\d+[-–]\d+"#, options: .regularExpression) {
                return "\(m[r]) år"
            }
        }

        // 3. ">X år" / "over X år"
        let overKws = ["hyppigst over ", "hyppig over ", "over ", "stiger kraftigt over ", "prævalens over "]
        for kw in overKws {
            if let idx = t.range(of: kw)?.upperBound {
                let after = String(t[idx...].prefix(8))
                if let nm = firstMatch(after, pattern: #"\d{2,3}"#),
                   let age = Int(nm), age >= 40, age <= 90 {
                    return ">\(age) år"
                }
            }
        }

        // 4. Barndom
        if ["barndom", "barnealder", "skolebørn", "barnealderen", "spædbarn",
            "0-3 år", "0–3 år", "debut i barn"].contains(where: { t.contains($0) }) {
            return "Barndom"
        }

        // 5. Alle aldre (eksplicit)
        if t.contains("alle aldersgrupper") || t.contains("alle aldre") ||
           t.contains("kan forekomme i alle aldre") || t.contains("rammer alle") {
            return "Alle aldre"
        }

        // 6. Ingen debutalder-info fundet
        return nil
    }

    // MARK: Regex-hjælpere

    private static func ratioAfter(_ t: String, keywords: [String]) -> String? {
        for kw in keywords {
            guard let end = t.range(of: kw)?.upperBound else { continue }
            let window = String(t[end...].prefix(25))
            if let r = firstMatch(window, pattern: #"ca\.\s*(\d+:\d+)"#) ??
                       firstMatch(window, pattern: #"\d+:\d+"#) {
                // Udtræk kun X:Y
                if let ratio = firstMatch(r, pattern: #"\d+:\d+"#) { return ratio }
            }
        }
        return nil
    }

    private static func multiplierBefore(_ t: String, hyppigere: Bool, near keyword: String) -> String? {
        guard t.contains(keyword) else { return nil }
        let pattern = #"(\d+(?:[,\.]\d+)?)\s*[x×]\s*hyppigere"#
        guard let m = firstMatch(t, pattern: pattern) else { return nil }
        return firstMatch(m, pattern: #"\d+"#)
    }

    private static func firstMatch(_ text: String, pattern: String) -> String? {
        guard let range = text.range(of: pattern, options: .regularExpression) else { return nil }
        return String(text[range])
    }
}

// MARK: - Hoved-visning

struct PrevalenceView: View {
    let diseases: [Disease]

    enum Grouping: String, CaseIterable {
        case chapter  = "Kapitel"
        case category = "Hyppighed"
    }

    @State private var grouping: Grouping = .chapter
    @State private var searchText = ""
    @State private var selectedDisease: Disease? = nil

    private var pool: [Disease] { diseases.filter { !$0.isTopic } }

    private var filtered: [Disease] {
        guard !searchText.isEmpty else { return pool }
        return pool.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var chapters: [String] {
        Array(Set(pool.map { $0.chapter })).sorted()
    }

    private func diseases(inChapter chapter: String) -> [Disease] {
        filtered.filter { $0.chapter == chapter }
            .sorted { FrequencyCategory.of($0).sortIndex < FrequencyCategory.of($1).sortIndex }
    }

    private func diseases(inCategory cat: FrequencyCategory) -> [Disease] {
        filtered.filter { FrequencyCategory.of($0) == cat }
            .sorted { $0.chapter == $1.chapter ? $0.name < $1.name : $0.chapter < $1.chapter }
    }

    // 2-kolonne grid
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if grouping == .chapter {
                    ForEach(chapters, id: \.self) { chapter in
                        let rows = diseases(inChapter: chapter)
                        if !rows.isEmpty {
                            chapterSection(chapter, rows: rows)
                        }
                    }
                } else {
                    ForEach(FrequencyCategory.allCases) { cat in
                        let rows = diseases(inCategory: cat)
                        if !rows.isEmpty {
                            categorySection(cat, rows: rows)
                        }
                    }
                }
            }
            .padding()
        }
        .searchable(text: $searchText, prompt: "Søg efter sygdom…")
        #if os(macOS)
        .navigationTitle("Forekomster")
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("", selection: $grouping) {
                    ForEach(Grouping.allCases, id: \.self) { Text($0.rawValue).tag($0) }
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

    // MARK: - Kapitel-sektion

    private func chapterSection(_ chapter: String, rows: [Disease]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: rows.first?.chapterIcon ?? "book")
                    .foregroundColor(.blue)
                Text(chapter)
                    .font(.title3.bold())
                Text("(\(rows.count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(rows) { disease in
                    diseaseCard(disease)
                }
            }
        }
    }

    // MARK: - Kategori-sektion

    private func categorySection(_ cat: FrequencyCategory, rows: [Disease]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: cat.icon).foregroundColor(cat.color)
                Text(cat.rawValue).font(.title3.bold()).foregroundColor(cat.color)
                Text("· \(cat.threshold)")
                    .font(.caption).foregroundColor(.secondary)
                Text("(\(rows.count))")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(rows) { disease in
                    diseaseCard(disease)
                }
            }
        }
    }

    // MARK: - Sygdomskort

    private func diseaseCard(_ disease: Disease) -> some View {
        let cat   = FrequencyCategory.of(disease)
        let facts = PrevalenceFacts.from(disease.prevalence)

        return Button { selectedDisease = disease } label: {
            VStack(alignment: .leading, spacing: 10) {

                // ── Navn + kategori-dot ──────────────────────
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(cat.color)
                        .frame(width: 10, height: 10)
                        .padding(.top, 5)
                    Text(disease.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }

                // ── Forekomsttekst (2–3 sætninger) ──────────
                Text(prevalenceText(disease.prevalence))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                // ── Køn + Debutalder chips (kun hvis pensum-data fundet) ─
                let hasChips = facts.sex != nil || facts.debut != nil
                if hasChips {
                    HStack(spacing: 6) {
                        if let s = facts.sex {
                            chip(icon: s.symbol, label: s.label, color: cat.color)
                        }
                        if let d = facts.debut {
                            chip(icon: "calendar", label: d, color: .gray)
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.platformSecondaryBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(cat.color.opacity(0.25), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func chip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(icon.count == 1 || icon.count == 2 ? icon : "")
                .font(.caption)
            if icon.count > 2 {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
            }
            Text(label)
                .font(.caption.bold())
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }

    // Første 2 sætninger fra prevalenstekst, max ~140 tegn
    private func prevalenceText(_ raw: String) -> String {
        var sentences: [String] = []
        var current = ""
        var i = raw.startIndex

        while i < raw.endIndex && sentences.count < 2 {
            let ch = raw[i]
            current.append(ch)
            if ch == "." {
                let next = raw.index(after: i)
                if next < raw.endIndex, raw[next] == " " {
                    let afterSpace = raw.index(after: next)
                    if afterSpace < raw.endIndex, raw[afterSpace].isUppercase {
                        sentences.append(current.trimmingCharacters(in: .whitespaces))
                        current = ""
                    }
                }
            }
            i = raw.index(after: i)
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
            sentences.append(current.trimmingCharacters(in: .whitespaces))
        }
        let joined = sentences.prefix(2).joined(separator: " ")
        return joined.count > 140 ? String(joined.prefix(137)) + "…" : joined
    }
}

private extension FrequencyCategory {
    var sortIndex: Int { FrequencyCategory.allCases.firstIndex(of: self) ?? 99 }
}
