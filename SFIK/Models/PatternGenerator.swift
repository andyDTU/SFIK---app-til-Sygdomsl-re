import Foundation
import SwiftUI

// MARK: - Data Models

struct PatternItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: [String]          // disease names
    let distractors: [String]     // wrong disease names
    let clue: String              // short hint / explanation
    let category: PatternCategory
}

enum PatternCategory: String, CaseIterable {
    case treatment = "Behandling"
    case genetics = "Genetik & Markører"
    case riskFactor = "Risikofaktorer"
    case pathogenesis = "Patogenese"
    case diagnostics = "Diagnostik"
    case complications = "Følgesygdomme"
    case epidemiology = "Epidemiologi"

    var icon: String {
        switch self {
        case .treatment: return "pills.fill"
        case .genetics: return "dna"
        case .riskFactor: return "exclamationmark.triangle.fill"
        case .pathogenesis: return "waveform.path.ecg"
        case .diagnostics: return "stethoscope"
        case .complications: return "arrow.triangle.branch"
        case .epidemiology: return "chart.bar.fill"
        }
    }

    var color: Color {
        switch self {
        case .treatment: return .blue
        case .genetics: return .purple
        case .riskFactor: return .orange
        case .pathogenesis: return .red
        case .diagnostics: return .teal
        case .complications: return .pink
        case .epidemiology: return .green
        }
    }
}

struct ThemeCluster: Identifiable {
    let id: String
    let title: String
    let description: String
    let diseases: [Disease]
    let keywords: [String]
}

struct DistinguisherPair: Identifiable {
    let id: String
    let title: String
    let diseaseA: Disease
    let diseaseB: Disease
    let commonTraits: [String]
    let uniqueA: [String]
    let uniqueB: [String]
}

// MARK: - Pattern Generator

enum PatternGenerator {

    // MARK: Keyword → matching diseases (manual, high-yield)
    static let treatmentKeywords: [(keyword: String, label: String)] = [
        ("TNF-alfa-hæmmere", "behandles med TNF-alfa-hæmmere"),
        ("NSAID", "behandles primært med NSAID"),
        ("binyrebarkhormon", "behandles med binyrebarkhormon"),
        ("levodopa", "behandles med levodopa"),
        ("insulin", "behandles med insulin"),
        ("metformin", "behandles med metformin"),
        ("statiner", "behandles med statiner"),
        ("trombolyse", "behandles akut med trombolyse"),
        ("ACE-hæmmere", "behandles med ACE-hæmmere"),
        ("betablokkere", "behandles med betablokkere"),
        ("kolinesterasehæmmere", "behandles med kolinesterasehæmmere"),
        ("antiepileptisk", "behandles med antiepileptisk medicin"),
        ("antipsykotika", "behandles med antipsykotika"),
        ("SSRI", "behandles med SSRI"),
        ("litium", "behandles med litium"),
        ("biologisk medicin", "behandles med biologisk medicin"),
        ("fysioterapi", "har fysioterapi som vigtig behandling"),
        ("træning", "har træning som vigtigste behandling"),
        ("vægttab", "har vægttab som første behandling"),
        ("allopurinol", "behandles langsigtet med allopurinol"),
        ("methotrexat", "behandles med methotrexat"),
    ]

    static let geneticKeywords: [(keyword: String, label: String)] = [
        ("HLA-B27", "har association med HLA-B27"),
        ("HLA-DR4", "har association med HLA-DR4"),
        ("APOE-ε4", "har association med APOE-ε4"),
        ("HLA-DRB1", "har association med HLA-DRB1"),
    ]

    static let riskFactorKeywords: [(keyword: String, label: String)] = [
        ("rygning", "har rygning som risikofaktor"),
        ("alkohol", "har alkohol som risikofaktor"),
        ("overvægt", "har overvægt som risikofaktor"),
        ("hypertension", "har hypertension som risikofaktor"),
        ("fedme", "har fedme som risikofaktor"),
        ("diabetes", "har diabetes som risikofaktor"),
        ("aldring", "har aldring som risikofaktor"),
    ]

    static let pathogenesisKeywords: [(keyword: String, label: String)] = [
        ("autoimmun", "er en autoimmun sygdom"),
        ("inflammation", "har inflammation som central patogenese"),
        ("degenerativ", "er en degenerativ sygdom"),
        ("demyelinisering", "har demyelinisering"),
        ("aterosklerose", "skyldes aterosklerose"),
        ("amyloid", "har amyloid-aflejring"),
        ("trombe", "skyldes trombedannelse"),
        ("emboli", "skyldes emboli"),
        ("dopamin", "skyldes dopamin-mangel"),
        ("urinsyre", "skyldes urinsyre"),
    ]

    static let diagnosticKeywords: [(keyword: String, label: String)] = [
        ("MR-scanning", "diagnosticeres med MR-scanning"),
        ("CT-scanning", "diagnosticeres med CT-scanning"),
        ("EEG", "diagnosticeres med EEG"),
        ("røntgen", "diagnosticeres med røntgen"),
        ("blodprøve", "diagnosticeres med blodprøver"),
        ("ultralyd", "diagnosticeres med ultralyd"),
        ("biopsi", "diagnosticeres med biopsi"),
    ]

    // MARK: - Pattern Discovery

    static func generatePatterns(from diseases: [Disease]) -> [PatternItem] {
        var items: [PatternItem] = []
        let pool = diseases.filter { !$0.isTopic }

        items += buildPatterns(pool, keywords: treatmentKeywords, category: .treatment)
        items += buildPatterns(pool, keywords: geneticKeywords, category: .genetics)
        items += buildPatterns(pool, keywords: riskFactorKeywords, category: .riskFactor)
        items += buildPatterns(pool, keywords: pathogenesisKeywords, category: .pathogenesis)
        items += buildPatterns(pool, keywords: diagnosticKeywords, category: .diagnostics)

        // Hard-coded high-yield patterns not captured by simple keyword search
        items += manualPatterns(pool)

        return items.shuffled()
    }

    private static func buildPatterns(
        _ pool: [Disease],
        keywords: [(keyword: String, label: String)],
        category: PatternCategory
    ) -> [PatternItem] {
        var result: [PatternItem] = []
        for (kw, label) in keywords {
            let matches = pool.filter { diseaseMatches($0, keyword: kw) }
            guard matches.count >= 2 else { continue }

            let answer = matches.map { $0.name }
            let distractors = pool
                .filter { !matches.contains($0) }
                .shuffled()
                .prefix(4)
                .map { $0.name }

            let question = "Hvilke sygdomme \(label)?"
            let clue = "\(matches.count) sygdomme deler dette træk."

            result.append(PatternItem(
                question: question,
                answer: answer,
                distractors: distractors,
                clue: clue,
                category: category
            ))
        }
        return result
    }

    private static func diseaseMatches(_ disease: Disease, keyword: String) -> Bool {
        let allText = [
            disease.definition, disease.prevalence, disease.pathogenesis,
            disease.etiology, disease.symptoms, disease.diagnostics,
            disease.treatment, disease.prognosis, disease.burden,
            disease.complications ?? ""
        ].joined(separator: " ").lowercased()
        return allText.contains(keyword.lowercased())
    }

    // MARK: Manual high-yield patterns
    private static func manualPatterns(_ pool: [Disease]) -> [PatternItem] {
        var items: [PatternItem] = []

        // By age group
        let children = pool.filter {
            diseaseMatches($0, keyword: "børn") || diseaseMatches($0, keyword: "barndom")
        }
        if children.count >= 2 {
            let answer = children.map { $0.name }
            let distractors = pool.filter { !children.contains($0) }.shuffled().prefix(4).map { $0.name }
            items.append(PatternItem(
                question: "Hvilke sygdomme debuterer primært i barndommen?",
                answer: answer,
                distractors: distractors,
                clue: "\(children.count) sygdomme i pensum debuterer i barndommen.",
                category: .epidemiology
            ))
        }

        // Causes dementia
        let dementia = pool.filter {
            diseaseMatches($0, keyword: "demens") || diseaseMatches($0, keyword: "demens")
        }
        if dementia.count >= 2 {
            let answer = dementia.map { $0.name }
            let distractors = pool.filter { !dementia.contains($0) }.shuffled().prefix(4).map { $0.name }
            items.append(PatternItem(
                question: "Hvilke sygdomme kan medføre demens?",
                answer: answer,
                distractors: distractors,
                clue: "\(dementia.count) sygdomme i pensum kan føre til demens.",
                category: .complications
            ))
        }

        // Causes depression
        let depressionRisk = pool.filter {
            diseaseMatches($0, keyword: "depression") && $0.name != "Depression (unipolar)"
        }
        if depressionRisk.count >= 2 {
            let answer = depressionRisk.map { $0.name }
            let distractors = pool.filter { !depressionRisk.contains($0) }.shuffled().prefix(4).map { $0.name }
            items.append(PatternItem(
                question: "Hvilke sygdomme har øget risiko for depression?",
                answer: answer,
                distractors: distractors,
                clue: "\(depressionRisk.count) sygdomme i pensum har øget depressionrisiko.",
                category: .complications
            ))
        }

        return items
    }

    // MARK: - Theme Clusters

    static func themeClusters(from diseases: [Disease]) -> [ThemeCluster] {
        let pool = diseases.filter { !$0.isTopic }
        var clusters: [ThemeCluster] = []

        // Autoimmune diseases
        let autoimmune = pool.filter { diseaseMatches($0, keyword: "autoimmun") }
        if autoimmune.count >= 2 {
            clusters.append(ThemeCluster(
                id: "autoimmune",
                title: "Autoimmune sygdomme",
                description: "Sygdomme hvor immunsystemet angriber kroppens egne væv.",
                diseases: autoimmune,
                keywords: ["autoimmun", "antistoffer", "inflammation"]
            ))
        }

        // Degenerative diseases
        let degenerative = pool.filter { diseaseMatches($0, keyword: "degenerativ") || diseaseMatches($0, keyword: "degeneration") }
        if degenerative.count >= 2 {
            clusters.append(ThemeCluster(
                id: "degenerative",
                title: "Degenerative sygdomme",
                description: "Progressiv nedbrydning af væv og celler.",
                diseases: degenerative,
                keywords: ["degenerativ", "progressiv", "atrofi"]
            ))
        }

        // Vascular diseases
        let vascular = pool.filter {
            diseaseMatches($0, keyword: "iskæmi") || diseaseMatches($0, keyword: "arteriosklerose") ||
            diseaseMatches($0, keyword: "trombe") || diseaseMatches($0, keyword: "emboli") ||
            diseaseMatches($0, keyword: "hypertension") && (diseaseMatches($0, keyword: "hjerte") || diseaseMatches($0, keyword: "apopleksi"))
        }
        if vascular.count >= 2 {
            clusters.append(ThemeCluster(
                id: "vascular",
                title: "Vaskulære sygdomme",
                description: "Sygdomme i blodkar og kredsløb.",
                diseases: vascular,
                keywords: ["iskæmi", "trombe", "emboli", "aterosklerose"]
            ))
        }

        // Metabolic / lifestyle diseases
        let metabolic = pool.filter {
            diseaseMatches($0, keyword: "insulin") || diseaseMatches($0, keyword: "metabolisk") ||
            diseaseMatches($0, keyword: "overvægt") || diseaseMatches($0, keyword: "fedme") ||
            $0.name.contains("Diabetes") || $0.name.contains("diabetes")
        }
        if metabolic.count >= 2 {
            clusters.append(ThemeCluster(
                id: "metabolic",
                title: "Metaboliske & livsstilssygdomme",
                description: "Sygdomme knyttet til stofskifte, kost og livsstil.",
                diseases: metabolic,
                keywords: ["insulin", "metabolisk", "overvægt", "livsstil"]
            ))
        }

        // Inflammatory diseases
        let inflammatory = pool.filter {
            diseaseMatches($0, keyword: "inflammation") && !autoimmune.contains($0)
        }
        if inflammatory.count >= 2 {
            clusters.append(ThemeCluster(
                id: "inflammatory",
                title: "Inflammatoriske sygdomme (ikke-autoimmune)",
                description: "Sygdomme med inflammation uden autoimmun mekanisme.",
                diseases: inflammatory,
                keywords: ["inflammation", "neutrofiler", "cytokiner"]
            ))
        }

        // Neurodegenerative
        let neurodegen = pool.filter {
            diseaseMatches($0, keyword: "neurodegenerativ") || diseaseMatches($0, keyword: "dopamin") ||
            diseaseMatches($0, keyword: "amyloid") || diseaseMatches($0, keyword: "tau") ||
            diseaseMatches($0, keyword: "Lewy bodies")
        }
        if neurodegen.count >= 2 {
            clusters.append(ThemeCluster(
                id: "neurodegen",
                title: "Neurodegenerative sygdomme",
                description: "Progressiv degeneration af nerveceller.",
                diseases: neurodegen,
                keywords: ["neurodegenerativ", "dopamin", "amyloid", "tau"]
            ))
        }

        // Cancer
        let cancer = pool.filter { diseaseMatches($0, keyword: "kræft") || diseaseMatches($0, keyword: "tumor") || diseaseMatches($0, keyword: "malign") }
        if cancer.count >= 2 {
            clusters.append(ThemeCluster(
                id: "cancer",
                title: "Kræftsygdomme",
                description: "Maligne sygdomme med ukontrolleret cellevækst.",
                diseases: cancer,
                keywords: ["kræft", "tumor", "malign", "metastase"]
            ))
        }

        // Psychiatric
        let psychiatric = pool.filter { $0.chapter == "Psykiske sygdomme" }
        if psychiatric.count >= 2 {
            clusters.append(ThemeCluster(
                id: "psychiatric",
                title: "Psykiske sygdomme",
                description: "Sygdomme i det mentale spektrum.",
                diseases: psychiatric,
                keywords: ["psykose", "depression", "mani", "hallucination"]
            ))
        }

        return clusters
    }

    // MARK: - Distinguisher Pairs

    static func distinguisherPairs(from diseases: [Disease]) -> [DistinguisherPair] {
        let pool = diseases.filter { !$0.isTopic }
        var pairs: [DistinguisherPair] = []

        // Find similar diseases by shared chapter or shared keywords
        let chapterGroups = Dictionary(grouping: pool, by: { $0.chapter })

        for (_, group) in chapterGroups {
            guard group.count >= 2 else { continue }
            for i in 0..<group.count {
                for j in (i+1)..<group.count {
                    let a = group[i], b = group[j]
                    let (common, uniqueA, uniqueB) = compare(a, b)
                    guard common.count >= 1 || uniqueA.count >= 1 || uniqueB.count >= 1 else { continue }
                    pairs.append(DistinguisherPair(
                        id: "\(a.id)__\(b.id)",
                        title: "\(a.name) vs. \(b.name)",
                        diseaseA: a, diseaseB: b,
                        commonTraits: common, uniqueA: uniqueA, uniqueB: uniqueB
                    ))
                }
            }
        }

        // Prioritize known high-yield pairs first
        let highYieldPairs = ComparisonPair.all.compactMap { pair -> DistinguisherPair? in
            guard let a = pool.first(where: { $0.id == pair.idA }),
                  let b = pool.first(where: { $0.id == pair.idB }) else { return nil }
            let (common, uniqueA, uniqueB) = compare(a, b)
            return DistinguisherPair(
                id: pair.id, title: pair.title,
                diseaseA: a, diseaseB: b,
                commonTraits: common, uniqueA: uniqueA, uniqueB: uniqueB
            )
        }

        // Merge: high-yield first, then the rest
        let highYieldIds = Set(highYieldPairs.map { $0.id })
        let remaining = pairs.filter { !highYieldIds.contains($0.id) }
        return highYieldPairs + remaining.shuffled()
    }

    private static func compare(_ a: Disease, _ b: Disease) -> (common: [String], uniqueA: [String], uniqueB: [String]) {
        let fields: [(String, String, String)] = [
            ("definition", a.definition, b.definition),
            ("pathogenese", a.pathogenesis, b.pathogenesis),
            ("ætiologi", a.etiology, b.etiology),
            ("symptomer", a.symptoms, b.symptoms),
            ("behandling", a.treatment, b.treatment),
            ("diagnostik", a.diagnostics, b.diagnostics),
            ("prognose", a.prognosis, b.prognosis),
        ]

        var common: [String] = []
        var uniqueA: [String] = []
        var uniqueB: [String] = []

        for (label, fa, fb) in fields {
            let ta = fa.trimmingCharacters(in: .whitespacesAndNewlines)
            let tb = fb.trimmingCharacters(in: .whitespacesAndNewlines)
            if ta.isEmpty && tb.isEmpty { continue }
            if ta == tb && !ta.isEmpty {
                common.append("\(label): \(ta)")
            } else {
                if !ta.isEmpty { uniqueA.append("\(label): \(ta)") }
                if !tb.isEmpty { uniqueB.append("\(label): \(tb)") }
            }
        }
        return (common, uniqueA, uniqueB)
    }
}
