import SwiftUI

/// Et forvekslingspar: to sygdomme der ligner hinanden og ofte forveksles til eksamen.
/// Defineres ved sygdommenes `id` (se diseases.json), så listen er robust over for
/// navneændringer. Par hvor en af sygdommene mangler, filtreres væk ved visning.
struct ComparisonPair: Identifiable {
    let title: String
    let idA: String
    let idB: String
    var id: String { "\(idA)__\(idB)" }

    /// Kuraterede høj-yield forvekslingspar fra pensum.
    static let all: [ComparisonPair] = [
        .init(title: "Type 1- vs. type 2-diabetes", idA: "diabetes_type1", idB: "diabetes_type2"),
        .init(title: "Hypertyreose vs. hypotyreose", idA: "hypertyreose", idB: "hypotyreose"),
        .init(title: "Stabil angina vs. akut myokardieinfarkt", idA: "angina_pectoris", idB: "hjerteinfarkt"),
        .init(title: "Astma vs. KOL", idA: "astma", idB: "kol"),
        .init(title: "Jernmangelanæmi vs. megaloblastær anæmi", idA: "anemi_jern", idB: "megaloblastaer_anaemi"),
        .init(title: "AML vs. ALL (akutte leukæmier)", idA: "leukemi_aml", idB: "akut_lymfoblastaer_leukaemi"),
        .init(title: "CML vs. CLL (kroniske leukæmier)", idA: "kronisk_myeloid_leukaemi", idB: "kronisk_lymfatisk_leukaemi"),
        .init(title: "Depression vs. bipolar lidelse", idA: "depression", idB: "bipolar"),
        .init(title: "Akut vs. kronisk nyresvigt", idA: "akut_nyresvigt", idB: "nyresvigt"),
        .init(title: "Cystitis (UVI) vs. pyelonefritis", idA: "urinvejsinfektioner", idB: "pyelonefritis"),
        .init(title: "Slidgigt vs. leddegigt", idA: "osteoartrose", idB: "ra"),
        .init(title: "Klamydia vs. gonorré", idA: "klamydia", idB: "gonorre"),
        .init(title: "Erysipelas vs. impetigo", idA: "erysipelas", idB: "impetigo"),
    ]
}

/// Liste over forvekslingspar; vælg et par for at se sygdommene side om side.
struct ComparisonView: View {
    let diseases: [Disease]
    @Environment(\.dismiss) private var dismiss

    private var byId: [String: Disease] {
        Dictionary(diseases.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    }

    /// Kun par hvor begge sygdomme findes i datasættet.
    private var availablePairs: [(pair: ComparisonPair, a: Disease, b: Disease)] {
        ComparisonPair.all.compactMap { pair in
            guard let a = byId[pair.idA], let b = byId[pair.idB] else { return nil }
            return (pair, a, b)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(availablePairs, id: \.pair.id) { item in
                        NavigationLink {
                            ComparisonDetailView(a: item.a, b: item.b)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.split.2x1")
                                    .foregroundColor(.indigo)
                                Text(item.pair.title)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                } footer: {
                    Text("Sammenlign sygdomme der ligner hinanden, felt for felt. Fokusér på den ene afgørende forskel.")
                }
            }
            .navigationTitle("Sammenlign (vs.)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Luk") { dismiss() }
                }
            }
        }
    }
}

/// Felt-for-felt sammenligning af to sygdomme, farvekodet (A = blå, B = orange).
struct ComparisonDetailView: View {
    let a: Disease
    let b: Disease

    private let colorA = Color.blue
    private let colorB = Color.orange

    /// (Titel, ikon, værdi for A, værdi for B) i kanonisk pensum-rækkefølge.
    private var rows: [(title: String, icon: String, valueA: String, valueB: String)] {
        let fields: [(String, String, (Disease) -> String)] = [
            ("Definition", "text.book.closed", { $0.definition }),
            ("Forekomst", "person.3", { $0.prevalence }),
            ("Patogenese", "waveform.path.ecg", { $0.pathogenesis }),
            ("Ætiologi", "magnifyingglass", { $0.etiology }),
            ("Symptomer", "thermometer", { $0.symptoms }),
            ("Diagnostik", "stethoscope", { $0.diagnostics }),
            ("Behandling", "pills", { $0.treatment }),
            ("Følgesygdomme", "arrow.triangle.branch", { $0.complications ?? "" }),
            ("Prognose", "chart.line.uptrend.xyaxis", { $0.prognosis }),
            ("Byrde", "exclamationmark.triangle", { $0.burden }),
        ]
        return fields.compactMap { title, icon, get in
            let va = get(a).trimmingCharacters(in: .whitespacesAndNewlines)
            let vb = get(b).trimmingCharacters(in: .whitespacesAndNewlines)
            // Spring felter over hvor begge er tomme (fx på temakort).
            if va.isEmpty && vb.isEmpty { return nil }
            return (title, icon, va, vb)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                legend

                ForEach(rows, id: \.title) { row in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: row.icon)
                                .foregroundColor(.indigo)
                            Text(row.title)
                                .font(.title3)
                                .bold()
                        }
                        sideBlock(name: a.name, value: row.valueA, color: colorA)
                        sideBlock(name: b.name, value: row.valueB, color: colorB)
                    }
                    .padding(.bottom, 6)
                    Divider()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Sammenlign")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    /// Lille forklaring øverst med de to navne og deres farve.
    private var legend: some View {
        HStack(spacing: 16) {
            legendChip(name: a.name, color: colorA)
            Text("vs.")
                .font(.headline)
                .foregroundColor(.secondary)
            legendChip(name: b.name, color: colorB)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func legendChip(name: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(name)
                .font(.subheadline).bold()
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
    }

    /// Ét farvekodet tekstblok for én sygdom, med venstre kantfarve.
    private func sideBlock(name: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.caption).bold()
                .foregroundColor(color)
            Text(value.isEmpty ? "—" : value)
                .font(.body)
                .foregroundColor(value.isEmpty ? .secondary : .primary)
        }
        .padding(.leading, 10)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            Rectangle()
                .fill(color)
                .frame(width: 3)
                .clipShape(Capsule()),
            alignment: .leading
        )
    }
}
