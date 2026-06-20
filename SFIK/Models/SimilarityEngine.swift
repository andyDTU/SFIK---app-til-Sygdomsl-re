import Foundation
import SwiftUI

// MARK: - Feltkategori

enum SimilarityCategory: String, CaseIterable, Identifiable {
    case diagnostik   = "Diagnostik"
    case behandling   = "Behandling"
    case patogenese   = "Patogenese"
    case aetiologi    = "Ætiologi & Risiko"
    case symptomer    = "Symptomer"
    case komplikation = "Komplikationer"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .diagnostik:   return "stethoscope"
        case .behandling:   return "pills.fill"
        case .patogenese:   return "waveform.path.ecg"
        case .aetiologi:    return "exclamationmark.triangle.fill"
        case .symptomer:    return "thermometer.medium"
        case .komplikation: return "arrow.triangle.branch"
        }
    }

    var color: Color {
        switch self {
        case .diagnostik:   return .blue
        case .behandling:   return .green
        case .patogenese:   return .purple
        case .aetiologi:    return .orange
        case .symptomer:    return .red
        case .komplikation: return .pink
        }
    }
}

// MARK: - Datapunkt

struct SimilarityTrait: Identifiable {
    let id = UUID()
    let keyword: String
    let category: SimilarityCategory
    let diseases: [Disease]
}

// MARK: - Udtrækningsmaskine

enum SimilarityEngine {

    private struct KeyDef {
        let display: String
        let terms: [String]          // Et match er nok (case-insensitivt)
        let category: SimilarityCategory
        let fields: [KeyPath<Disease, String>]
        let optionalFields: [KeyPath<Disease, String?>]

        init(_ display: String,
             terms: [String],
             cat: SimilarityCategory,
             fields: [KeyPath<Disease, String>] = [],
             opt: [KeyPath<Disease, String?>] = []) {
            self.display = display
            self.terms = terms
            self.category = cat
            self.fields = fields
            self.optionalFields = opt
        }

        func text(from d: Disease) -> String {
            let a = fields.map { d[keyPath: $0] }.joined(separator: " ")
            let b = optionalFields.compactMap { d[keyPath: $0] }.joined(separator: " ")
            return (a + " " + b).lowercased()
        }

        func matches(_ d: Disease) -> Bool {
            let t = text(from: d)
            return terms.contains { t.contains($0.lowercased()) }
        }
    }

    // MARK: - Nøgleordsdefinitioner

    private static let definitions: [KeyDef] = [

        // ── DIAGNOSTIK ────────────────────────────────────────────

        .init("MR-scanning",
              terms: ["mr-scanning", "mr-skanning", "mri", "magnetisk resonans"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("CT-scanning",
              terms: ["ct-scanning", "ct-skanning", "computertomografi"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("EEG",
              terms: ["eeg"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Røntgen",
              terms: ["røntgen"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Ultralyd",
              terms: ["ultralyd"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Biopsi",
              terms: ["biopsi"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("PET-scanning",
              terms: ["pet-scanning", "pet-scan", "positron"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Gastroskopi",
              terms: ["gastroskopi", "gastroskop"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Koloskopi",
              terms: ["koloskopi"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Spirometri",
              terms: ["spirometri"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("EKG",
              terms: ["ekg", "elektrokardiografi"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Ekkokardiografi",
              terms: ["ekkokardiografi"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Blodprøver & CRP",
              terms: ["blodprøve", "crp", "leukocyt"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Lumbalpunktur",
              terms: ["lumbalpunktur", "cerebrospinalvæske", "rygmarvsvæske"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("HbA1c",
              terms: ["hba1c"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("TSH / skjoldbruskkirtel",
              terms: ["tsh"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("DEXA / knogledensitet",
              terms: ["dexa", "knogledensitet", "knoglemineraltæthed", "dxa"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Troponin",
              terms: ["troponin"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("D-dimer",
              terms: ["d-dimer"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("PSA",
              terms: ["psa"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Knoglemarvsundersøgelse",
              terms: ["knoglemarvsundersøgelse", "knoglemarv"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Mammografi",
              terms: ["mammografi"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Bronkoskopi",
              terms: ["bronkoskopi"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Urinstix / urindyrkning",
              terms: ["urinstix", "urindyrkning", "urinprøve"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("Kolesterol & lipider",
              terms: ["kolesterol", "ldl", "hdl", "lipid"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        .init("ABI (ankel-brachial-indeks)",
              terms: ["abi", "ankel-brachial", "ankle-brachial"],
              cat: .diagnostik, fields: [\.diagnostics], opt: [\.details]),

        // ── BEHANDLING ────────────────────────────────────────────

        .init("TNF-alfa-hæmmere",
              terms: ["tnf-alfa", "tnf alfa", "anti-tnf"],
              cat: .behandling, fields: [\.treatment]),

        .init("Biologisk medicin",
              terms: ["biologisk medicin", "biologiske lægemidler"],
              cat: .behandling, fields: [\.treatment]),

        .init("Insulin",
              terms: ["insulin"],
              cat: .behandling, fields: [\.treatment]),

        .init("Metformin",
              terms: ["metformin"],
              cat: .behandling, fields: [\.treatment]),

        .init("GLP-1 / SGLT-2",
              terms: ["glp-1", "sglt-2", "glp1", "sglt2"],
              cat: .behandling, fields: [\.treatment]),

        .init("Antibiotika",
              terms: ["antibiotika", "penicillin", "cefalosporin", "amoxicillin", "doxycyklin"],
              cat: .behandling, fields: [\.treatment]),

        .init("Kortikosteroider",
              terms: ["kortikosteroider", "binyrebarkhormon", "prednisolon", "kortison"],
              cat: .behandling, fields: [\.treatment]),

        .init("NSAID",
              terms: ["nsaid"],
              cat: .behandling, fields: [\.treatment]),

        .init("Kemoterapi",
              terms: ["kemoterapi"],
              cat: .behandling, fields: [\.treatment]),

        .init("Kirurgi / operation",
              terms: ["kirurgi", "operation", "operativ", "kirurgisk"],
              cat: .behandling, fields: [\.treatment]),

        .init("Strålebehandling",
              terms: ["strålebehandling"],
              cat: .behandling, fields: [\.treatment]),

        .init("SSRI / antidepressiva",
              terms: ["ssri", "antidepressiva"],
              cat: .behandling, fields: [\.treatment]),

        .init("Antipsykotika",
              terms: ["antipsykotika"],
              cat: .behandling, fields: [\.treatment]),

        .init("Betablokkere",
              terms: ["betablokkere", "beta-blokkere"],
              cat: .behandling, fields: [\.treatment]),

        .init("ACE-hæmmere / ARB",
              terms: ["ace-hæmmere", "arb", "losartan", "ramipril"],
              cat: .behandling, fields: [\.treatment]),

        .init("Antikoagulation",
              terms: ["antikoagulation", "antikoagulans", "doak", "warfarin", "heparin"],
              cat: .behandling, fields: [\.treatment]),

        .init("Trombolyse",
              terms: ["trombolyse"],
              cat: .behandling, fields: [\.treatment]),

        .init("Statin",
              terms: ["statin"],
              cat: .behandling, fields: [\.treatment]),

        .init("Dialyse",
              terms: ["dialyse"],
              cat: .behandling, fields: [\.treatment]),

        .init("Immunosuppressiva",
              terms: ["immunosuppressiva", "azathioprin", "mykofenolat"],
              cat: .behandling, fields: [\.treatment]),

        .init("DMARD / Methotrexat",
              terms: ["dmard", "methotrexat"],
              cat: .behandling, fields: [\.treatment]),

        .init("PPI (protonpumpehæmmer)",
              terms: ["ppi", "protonpumpe", "omeprazol"],
              cat: .behandling, fields: [\.treatment]),

        .init("Levodopa",
              terms: ["levodopa"],
              cat: .behandling, fields: [\.treatment]),

        .init("Allopurinol",
              terms: ["allopurinol"],
              cat: .behandling, fields: [\.treatment]),

        .init("Bisfosfonat",
              terms: ["bisfosfonat", "alendronat", "zoledronsyre"],
              cat: .behandling, fields: [\.treatment]),

        .init("Fysioterapi / rehabilitering",
              terms: ["fysioterapi", "rehabilitering"],
              cat: .behandling, fields: [\.treatment]),

        .init("Antiepileptika",
              terms: ["antiepileptisk", "antiepileptika"],
              cat: .behandling, fields: [\.treatment]),

        .init("Lithium",
              terms: ["lithium", "litium"],
              cat: .behandling, fields: [\.treatment]),

        .init("Livsstilsændringer",
              terms: ["livsstilsændringer", "vægttab", "motion"],
              cat: .behandling, fields: [\.treatment]),

        .init("Oxygen / iltbehandling",
              terms: ["oxygen", "iltbehandling", "ilt "],
              cat: .behandling, fields: [\.treatment]),

        .init("Transplantation",
              terms: ["transplantation", "transplanteret"],
              cat: .behandling, fields: [\.treatment]),

        .init("Kolkicin",
              terms: ["kolkicin"],
              cat: .behandling, fields: [\.treatment]),

        .init("Mesalazin",
              terms: ["mesalazin"],
              cat: .behandling, fields: [\.treatment]),

        // ── PATOGENESE ────────────────────────────────────────────

        .init("Autoimmun",
              terms: ["autoimmun"],
              cat: .patogenese, fields: [\.pathogenesis, \.etiology]),

        .init("Inflammation",
              terms: ["inflammation", "inflammatorisk"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Aterosklerose",
              terms: ["aterosklerose", "arteriosklerose"],
              cat: .patogenese, fields: [\.pathogenesis, \.etiology]),

        .init("Degenerativ",
              terms: ["degenerativ", "degeneration"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Trombose",
              terms: ["trombose", "trombedannelse"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Iskæmi",
              terms: ["iskæmi", "iskæmisk"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Demyelinisering",
              terms: ["demyeliniserede", "myelinskeder", "demyelinisering"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Amyloid-aflejring",
              terms: ["amyloid"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Dopamin-mangel",
              terms: ["dopamin"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Insulinresistens",
              terms: ["insulinresistens"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Fibrose",
              terms: ["fibrose"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Nekrose",
              terms: ["nekrose"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Emboli",
              terms: ["emboli"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Autoantistoffer",
              terms: ["autoantistoffer", "autoantistof"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Urinsyre / hyperurikæmi",
              terms: ["urinsyre", "hyperurikæmi"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Hyperglykæmi",
              terms: ["hyperglykæmi"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Plaqueruptur",
              terms: ["plaqueruptur", "plakruptur"],
              cat: .patogenese, fields: [\.pathogenesis]),

        .init("Betacelle-destruktion",
              terms: ["betacelle", "beta-celle"],
              cat: .patogenese, fields: [\.pathogenesis]),

        // ── ÆTIOLOGI & RISIKO ─────────────────────────────────────

        .init("Rygning",
              terms: ["rygning", "tobak", "ryger"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("Alkohol",
              terms: ["alkohol"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("Overvægt / fedme",
              terms: ["overvægt", "fedme", "bmi"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("Hypertension (risikofaktor)",
              terms: ["hypertension"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("Diabetes (risikofaktor)",
              terms: ["diabetes"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("Genetisk / arvelig",
              terms: ["genetisk", "arvelig", "hereditær", "familiær disposition"],
              cat: .aetiologi, fields: [\.etiology]),

        .init("HLA-B27",
              terms: ["hla-b27"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("HLA-DR4",
              terms: ["hla-dr4"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("HPV",
              terms: ["hpv"],
              cat: .aetiologi, fields: [\.etiology]),

        .init("H. pylori",
              terms: ["helicobacter", "h. pylori", "h pylori"],
              cat: .aetiologi, fields: [\.etiology]),

        .init("Viral infektion",
              terms: ["viral infektion", "virusinfektion", "virus →"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("Bakteriel infektion",
              terms: ["bakteriel infektion", "bakterier →", "bakteriæmi"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("Stress",
              terms: ["stress"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("D-vitaminmangel",
              terms: ["d-vitaminmangel", "d-vitamin"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("Dyslipidæmi",
              terms: ["dyslipidæmi", "hyperlipidæmi", "hyperkolesterol"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("Østrogensvigt",
              terms: ["østrogen"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        .init("Immunsuppression",
              terms: ["immunsupprimeret", "immundefekt", "immunsvækket"],
              cat: .aetiologi, fields: [\.etiology, \.pathogenesis]),

        // ── SYMPTOMER ─────────────────────────────────────────────

        .init("Dyspnø / åndenød",
              terms: ["dyspnø", "åndenød", "kortåndet"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Hoste",
              terms: ["hoste"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Brystsmerter",
              terms: ["brystet", "brystsmerter", "brystsmerte", "prækordialt"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Feber",
              terms: ["feber", "temperaturforhøjelse"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Træthed / fatigue",
              terms: ["træthed", "fatigue"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Vægttab",
              terms: ["vægttab"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Ødem / hævelse",
              terms: ["ødem", "hævelse"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Smerter",
              terms: ["smerter"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Kvalme / opkastning",
              terms: ["kvalme", "opkastning"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Diarré",
              terms: ["diarré", "diarre"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Blødning",
              terms: ["blødning"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Hovedpine",
              terms: ["hovedpine", "cephale"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Bevidsthedstab / kramper",
              terms: ["bevidsthedstab", "kramper", "anfald"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Tremor / rysten",
              terms: ["tremor", "rysten"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Parese / lammelse",
              terms: ["parese", "lammelse"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Ledsmerte / artralgi",
              terms: ["ledsmerter", "artralgi", "ledsmerte"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Rygsmerter",
              terms: ["rygsmerter", "rygsmerte"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Polyuri / tørst",
              terms: ["polyuri", "polydipsi", "tørst"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Svimmelhed",
              terms: ["svimmelhed", "vertigo"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Hudforandringer / udslæt",
              terms: ["udslæt", "eksem", "hudforandring", "rødme"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Synsforstyrrelser",
              terms: ["synsforstyrrelser", "synstab", "diplopi", "dobbeltsyn"],
              cat: .symptomer, fields: [\.symptoms]),

        .init("Dysfagi / synkebesvær",
              terms: ["dysfagi", "synkebesvær"],
              cat: .symptomer, fields: [\.symptoms]),

        // ── KOMPLIKATIONER ────────────────────────────────────────

        .init("Hjerteinfarkt / AMI",
              terms: ["hjerteinfarkt", "myokardieinfarkt", "ami"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Apopleksi",
              terms: ["apopleksi", "slagtilfælde"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Nyresvigt / nefropati",
              terms: ["nyresvigt", "nefropati"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Depression (komplikation)",
              terms: ["depression"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Kræft / malignitet",
              terms: ["kræft", "malign", "karcinom"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Demens (komplikation)",
              terms: ["demens"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Fraktur / brud",
              terms: ["fraktur", "knoglebrud", "osteoporotisk"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Sepsis (komplikation)",
              terms: ["sepsis"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Anæmi",
              terms: ["anæmi"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Hjertesvigt",
              terms: ["hjertesvigt", "hjerteinsufficiens"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Lungeemboli",
              terms: ["lungeemboli"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("DVT",
              terms: ["dyb venøs", "dvt"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Neuropati",
              terms: ["neuropati"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Blindhed / synstab",
              terms: ["blindhed", "synstab"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Osteoporose (komplikation)",
              terms: ["osteoporose"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Infertilitet",
              terms: ["infertilitet", "infertil"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Amputation",
              terms: ["amputation", "amputeret"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Cirrose (komplikation)",
              terms: ["cirrose", "skrumpelever"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),

        .init("Respirationssvigt",
              terms: ["respirationssvigt"],
              cat: .komplikation, fields: [\.prognosis], opt: [\.complications]),
    ]

    // MARK: - Generér

    static func generate(from diseases: [Disease]) -> [SimilarityTrait] {
        let pool = diseases.filter { !$0.isTopic }
        return definitions.compactMap { def in
            let matching = pool.filter { def.matches($0) }
                .sorted { $0.name < $1.name }
            guard !matching.isEmpty else { return nil }
            return SimilarityTrait(keyword: def.display,
                                   category: def.category,
                                   diseases: matching)
        }
    }
}
