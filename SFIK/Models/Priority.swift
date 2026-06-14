import SwiftUI

/// Prioritet baseret på eksamensmønster (2016-2023) + at kursuslederen er
/// endokrinolog (alle endokrine emner er løftet til høj). Holdes i sync med
/// scripts/build_tracker.py.
enum Priority {
    case high, medium, low

    var label: String {
        switch self {
        case .high: return "Høj prioritet"
        case .medium: return "Mellem prioritet"
        case .low: return "Lav prioritet"
        }
    }

    var color: Color {
        switch self {
        case .high: return .orange
        case .medium: return .secondary
        case .low: return .gray
        }
    }
}

enum DiseasePriority {
    /// Tier 1 (eksamens-gengangere) + alle endokrine emner.
    static let high: Set<String> = [
        "parkinsons", "kol", "appendicitis", "spiseforstyrrelser", "myelomatose",
        "frakturer", "praeeklampsi", "apopleksi", "ekstrauterin_graviditet", "bipolar",
        "lungekraeft", "urinvejsinfektioner", "anemi_jern", "bechterew",
        "diabetes_type1", "diabetes_type2", "hypotyreose", "hypertyreose",
        "adipositas", "metabolisk_syndrom", "osteoporose",
    ]

    /// Lav-yield (sjældent/aldrig hovedtema).
    static let low: Set<String> = [
        "kondylomer", "gonorre", "klamydia", "polycytaemia_vera", "lymfom",
        "haemoragisk_diatese", "reaktiv_artrit", "artritis_urica", "malabsorption",
        "diarre", "megaloblastaer_anaemi", "cin", "benigne_ovariecyster",
        "postmenopausal_bloedning", "spontan_abort", "praetermfodsel",
        "urininkontinens", "adhd",
    ]

    static func tier(for disease: Disease) -> Priority {
        if high.contains(disease.id) { return .high }
        if low.contains(disease.id) { return .low }
        return .medium
    }
}
