import Foundation

/// Ét udfyld-hullet-kort: en sætning hvor et tal eller et lægemiddel er skjult.
struct ClozeItem: Identifiable {
    let id = UUID()
    let diseaseName: String
    let chapter: String
    let fieldLabel: String
    let prompt: String   // tekst med "_____"
    let answer: String
}

/// Genererer tal- og medicin-cloze automatisk fra de strukturerede felter.
enum ClozeGenerator {
    static let blank = "_____"

    /// Talmønstre i prioriteret rækkefølge (det første der matcher, bruges).
    /// Bevidst kun "interessante" tal (procent, tusinder, ratio/BT) — ikke løse cifre.
    private static let numberPatterns: [String] = [
        #"\d+(?:[.,]\d+)?\s?[–-]\s?\d+(?:[.,]\d+)?\s?%"#,   // interval-procent: 85-90 %
        #"\d+(?:[.,]\d+)?\s?%"#,                             // procent: 50 %
        #"\d{1,3}(?:\.\d{3})+"#,                             // tusinder: 19.000 / 950.000
        #"\d+/\d+(?:\s?mmHg)?"#,                             // ratio / blodtryk: 140/90
    ]

    /// Lægemidler/typer der er værd at kunne udenad (med almindelige bøjninger).
    private static let drugTerms: [String] = [
        "metformin", "insulin", "statiner", "statin", "ACE-hæmmere", "ACE-hæmmer",
        "warfarin", "adrenalin", "levothyroxin", "L-thyroxin", "penicillin",
        "nitroglycerin", "betablokkere", "betablokker", "NOAK", "heparin",
        "glukokortikoid", "bisfosfonater", "bisfosfonat", "denosumab", "methotrexat",
        "lithium", "trombolyse", "mesalazin", "azathioprin", "spironolacton"
    ]

    static func items(for diseases: [Disease], chapters: Set<String>) -> [ClozeItem] {
        var items: [ClozeItem] = []
        for d in diseases where !d.isTopic && chapters.contains(d.chapter) {
            if let it = numberCloze(text: d.prevalence, label: "Forekomst", disease: d) { items.append(it) }
            if let it = numberCloze(text: d.prognosis, label: "Prognose", disease: d) { items.append(it) }
            if let it = drugCloze(text: d.treatment, label: "Behandling", disease: d) { items.append(it) }
        }
        return items.shuffled()
    }

    // MARK: - Generatorer

    private static func numberCloze(text: String, label: String, disease: Disease) -> ClozeItem? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let ns = trimmed as NSString
        let full = NSRange(location: 0, length: ns.length)
        for pattern in numberPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            guard let match = regex.firstMatch(in: trimmed, range: full) else { continue }
            let answer = ns.substring(with: match.range)
            let prompt = ns.replacingCharacters(in: match.range, with: blank)
            return ClozeItem(diseaseName: disease.name, chapter: disease.chapter,
                             fieldLabel: label, prompt: prompt, answer: answer)
        }
        return nil
    }

    private static func drugCloze(text: String, label: String, disease: Disease) -> ClozeItem? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let ns = trimmed as NSString
        let full = NSRange(location: 0, length: ns.length)

        var best: NSRange? = nil
        for term in drugTerms {
            let escaped = NSRegularExpression.escapedPattern(for: term)
            // Hele ord (ingen bogstaver lige før/efter), så vi ikke rammer inde i andre ord.
            let pattern = "(?<![\\p{L}])\(escaped)(?![\\p{L}])"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
                  let match = regex.firstMatch(in: trimmed, range: full) else { continue }
            if best == nil || match.range.location < best!.location {
                best = match.range
            }
        }
        guard let range = best else { return nil }
        let answer = ns.substring(with: range)
        let prompt = ns.replacingCharacters(in: range, with: blank)
        return ClozeItem(diseaseName: disease.name, chapter: disease.chapter,
                         fieldLabel: label, prompt: prompt, answer: answer)
    }
}
