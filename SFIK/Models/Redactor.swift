import Foundation

/// Slører sygdommens navn OG afslørende beslægtede ord i en quiz-tekst, så
/// spørgsmålet ikke giver svaret væk. Ud over selve navnet fjernes ord, der
/// deler stamme/endelse med navnets ord (fx "Hoftebrud" når navnet er
/// "Frakturer (knoglebrud)").
enum Redactor {
    /// Generiske ord der indgår i mange sygdomsnavne – sløres ikke (ellers
    /// forsvinder neutral kontekst overalt).
    private static let stop: Set<String> = [
        "sygdom", "sygdomme", "sygdommen", "syndrom", "syndromet",
        "akut", "akutte", "kronisk", "kroniske", "primær", "sekundær"
    ]

    static func redact(name: String, in text: String) -> String {
        let tokens = name.lowercased()
            .components(separatedBy: CharacterSet(charactersIn: " /()-–,.'\""))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count >= 3 && !stop.contains($0) }
        guard !tokens.isEmpty else { return text }

        func reveals(_ w: String) -> Bool {
            for t in tokens {
                if w == t { return true }                       // eksakt (også forkortelser: KOL, AMI, HIV)
                if w.count >= 5 && t.count >= 5 {
                    if w.contains(t) || t.contains(w) { return true }   // delord (hofte+brud)
                    if prefixLen(w, t) >= 6 { return true }             // fælles stamme (fraktur-)
                    if suffixLen(w, t) >= 5 { return true }             // fælles endelse (-ebrud)
                }
            }
            return false
        }

        let ns = text as NSString
        guard let regex = try? NSRegularExpression(pattern: "[\\p{L}]{3,}") else { return text }
        var out = ""
        var last = 0
        for m in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            let r = m.range
            out += ns.substring(with: NSRange(location: last, length: r.location - last))
            let word = ns.substring(with: r)
            out += reveals(word.lowercased()) ? "___" : word
            last = r.location + r.length
        }
        out += ns.substring(from: last)

        // Saml flere blanke ud i ét.
        while out.contains("___ ___") { out = out.replacingOccurrences(of: "___ ___", with: "___") }
        out = out.replacingOccurrences(of: "______", with: "___")
        return out
    }

    private static func prefixLen(_ a: String, _ b: String) -> Int {
        let aa = Array(a), bb = Array(b); var i = 0
        while i < aa.count && i < bb.count && aa[i] == bb[i] { i += 1 }
        return i
    }

    private static func suffixLen(_ a: String, _ b: String) -> Int {
        let aa = Array(a), bb = Array(b); var i = 0
        while i < aa.count && i < bb.count && aa[aa.count - 1 - i] == bb[bb.count - 1 - i] { i += 1 }
        return i
    }
}
