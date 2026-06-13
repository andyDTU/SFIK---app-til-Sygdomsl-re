import Foundation

/// Retning på et flashcard.
enum FlashcardDirection: Hashable {
    case produce   // Sygdom + felt → genkald indholdet (eksamensretningen)
    case identify  // Indhold → genkend sygdommen
}

struct Flashcard: Identifiable {
    let id = UUID()
    let disease: Disease
    let category: String
    let content: String
    var direction: FlashcardDirection = .produce

    /// Stabil nøgle på tværs af sessioner (uafhængig af retning),
    /// så spaced repetition kan huske kortets tilstand.
    var key: String { "\(disease.id)::\(category)" }
}
