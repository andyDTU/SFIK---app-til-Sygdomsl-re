import Foundation

extension Disease {
    /// (kategori, indhold)-par for sygdommen — kun ikke-tomme felter, i fast
    /// pensum-rækkefølge. Bruges af både flashcards og fremdrifts-oversigten,
    /// så de deler nøjagtig samme kort (og dermed samme repetitions-nøgler).
    var flashcardEntries: [(category: String, content: String)] {
        var e: [(String, String)] = []
        if !definition.isEmpty { e.append(("Definition", definition)) }
        if !prevalence.isEmpty { e.append(("Forekomst", prevalence)) }
        let pe = [pathogenesis, etiology].filter { !$0.isEmpty }.joined(separator: "\n\n")
        if !pe.isEmpty { e.append(("Patogenese & Ætiologi", pe)) }
        if !symptoms.isEmpty { e.append(("Symptomer & Fund", symptoms)) }
        if !diagnostics.isEmpty { e.append(("Diagnostik", diagnostics)) }
        if !treatment.isEmpty { e.append(("Behandling & Forebyggelse", treatment)) }
        if let c = complications, !c.isEmpty { e.append(("Følgesygdomme", c)) }
        if !prognosis.isEmpty { e.append(("Prognose", prognosis)) }
        if !burden.isEmpty { e.append(("Byrde", burden)) }
        return e.map { (category: $0.0, content: $0.1) }
    }

    /// Stabile repetitions-nøgler for sygdommens kort.
    var flashcardKeys: [String] {
        flashcardEntries.map { "\(id)::\($0.category)" }
    }
}
