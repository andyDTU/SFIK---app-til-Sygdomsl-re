import Foundation

struct Disease: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let chapter: String
    let chapterIcon: String
    let definition: String
    let prevalence: String
    let pathogenesis: String
    let etiology: String
    let symptoms: String
    let diagnostics: String
    let treatment: String
    let prognosis: String
    let burden: String
    /// Følgesygdomme/komplikationer. Valgfri af hensyn til bagudkompatibilitet.
    let complications: String?
    /// Pensum-kilde (lærebogens kapitel). Valgfri af hensyn til bagudkompatibilitet.
    let source: String?
    /// "topic" for tema-kort (ikke-sygdomme, fx Kap. 1 og 16). nil for almindelige sygdomskort.
    let type: String?
    /// Uddybende noter (valgfri dybde-tekst). Vises som ekstra sektion i detaljevisningen.
    let details: String?

    /// Tema-kort dækker ikke en enkeltsygdom og bør udelades fra sygdoms-quizzer.
    var isTopic: Bool { type == "topic" }
}
