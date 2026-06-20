import SwiftUI

enum Priority {
    case high       // Primær fokus (sikreste eksamensemner)
    case secondary  // Sekundær fokus (bredt men realistisk)
    case medium     // Generelt pensum
    case low        // Lav-yield

    var label: String {
        switch self {
        case .high:      return "Primær fokus"
        case .secondary: return "Sekundær fokus"
        case .medium:    return "Generelt pensum"
        case .low:       return "Lav prioritet"
        }
    }

    var color: Color {
        switch self {
        case .high:      return .orange
        case .secondary: return .blue
        case .medium:    return .secondary
        case .low:       return .gray
        }
    }
}

enum DiseasePriority {

    // MARK: Primær fokus — 28 sygdomme

    /// Sikreste eksamensemner baseret på eksamenshistorik + kursusleder er endokrinolog.
    static let primary: Set<String> = [
        // Neurologi
        "apopleksi", "parkinsons", "demens_alzheimers",
        // Psykiatri
        "depression", "bipolar", "spiseforstyrrelser",
        // Hjerte-kar (TIDLIGERE TOMT — nu tilføjet)
        "hypertension", "hjerteinfarkt", "hjertesvigt",
        // Lunger
        "kol", "astma", "pneumoni",
        // Endokrinologi (alle — kursusleder er endokrinolog)
        "diabetes_type1", "diabetes_type2", "hypotyreose", "hypertyreose",
        "adipositas", "metabolisk_syndrom", "osteoporose",
        // Bevægeapparat
        "ra", "frakturer", "bechterew",
        // Infektioner
        "sepsis", "urinvejsinfektioner",
        // Mave-tarm
        "appendicitis",
        // Blod
        "anemi_jern",
        // Gynækologi
        "praeeklampsi",
        // Kræft
        "lungekraeft",
    ]

    // MARK: Sekundær fokus — 17 sygdomme

    /// Realistiske eksamensemner — tænk bredt, men disse er mindre sikre.
    static let secondary: Set<String> = [
        // Hjerte-kar
        "atrieflimren", "aterosklerose",
        // Neurologi
        "epilepsi", "multipel_sklerose",
        // Psykiatri
        "angst", "skizofreni",
        // Bevægeapparat
        "osteoartrose", "proksimal_femurfraktur",
        // Kræft
        "myelomatose", "brystkraeft", "tyktarmskraeft",
        // Mave-tarm
        "ibd", "cirrose", "ulcus",
        // Nyre
        "nyresvigt",
        // Gynækologi
        "pcos", "ekstrauterin_graviditet",
    ]

    // MARK: Lav-yield

    /// Sjældent eller aldrig eksamens-hovedtema.
    static let low: Set<String> = [
        "kondylomer", "gonorre", "klamydia", "polycytaemia_vera", "lymfom",
        "haemoragisk_diatese", "reaktiv_artrit", "artritis_urica", "malabsorption",
        "diarre", "megaloblastaer_anaemi", "cin", "benigne_ovariecyster",
        "postmenopausal_bloedning", "spontan_abort", "praetermfodsel",
        "urininkontinens", "adhd",
    ]

    // Backward compat — .high er nu primær fokus
    static let high: Set<String> = primary

    static func tier(for disease: Disease) -> Priority {
        if primary.contains(disease.id)   { return .high }
        if secondary.contains(disease.id) { return .secondary }
        if low.contains(disease.id)       { return .low }
        return .medium
    }
}
