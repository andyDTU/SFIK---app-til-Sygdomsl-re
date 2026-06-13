import SwiftUI

/// Fri-genkaldelse ("blurting"): du får én sygdom ad gangen, reciterer alle
/// felter af hukommelsen, krydser af hvad du huskede, og afslører så facit.
/// Spejler den mundtlige/skriftlige eksamenssituation.
struct ExamRecallView: View {
    let diseases: [Disease]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedChapters: Set<String> = []
    @State private var sessionDiseases: [Disease]? = nil

    private var allChapters: [String] {
        Array(Set(diseases.filter { !$0.isTopic }.map { $0.chapter })).sorted()
    }

    private var sessionCount: Int {
        diseases.filter { !$0.isTopic && selectedChapters.contains($0.chapter) }.count
    }

    private var canStart: Bool { !selectedChapters.isEmpty && sessionCount > 0 }

    var body: some View {
        NavigationStack {
            Group {
                if let session = sessionDiseases {
                    ExamRecallSession(diseases: session) { sessionDiseases = nil }
                } else {
                    selectionScreen
                }
            }
            .navigationTitle(sessionDiseases == nil ? "Eksamens-genkaldelse" : "Genkaldelse")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if sessionDiseases != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { sessionDiseases = nil } label: {
                            Label("Emner", systemImage: "chevron.left")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Luk") { dismiss() }
                }
            }
            .onAppear { if selectedChapters.isEmpty { selectedChapters = Set(allChapters) } }
        }
    }

    private var selectionScreen: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(allChapters, id: \.self) { chapter in
                        Button {
                            if selectedChapters.contains(chapter) { selectedChapters.remove(chapter) }
                            else { selectedChapters.insert(chapter) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedChapters.contains(chapter) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedChapters.contains(chapter) ? .blue : .secondary)
                                Text(chapter).foregroundColor(.primary)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack {
                        Text("Kapitler")
                        Spacer()
                        Button(selectedChapters.count == allChapters.count ? "Fravælg alle" : "Vælg alle") {
                            if selectedChapters.count == allChapters.count { selectedChapters.removeAll() }
                            else { selectedChapters = Set(allChapters) }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                    }
                } footer: {
                    Text("Du får én sygdom ad gangen. Recitér alle felter af hukommelsen, kryds af hvad du huskede, og afslør så facit.")
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif

            VStack(spacing: 0) {
                Divider()
                Button {
                    sessionDiseases = diseases
                        .filter { !$0.isTopic && selectedChapters.contains($0.chapter) }
                        .shuffled()
                } label: {
                    Text(canStart ? "Start (\(sessionCount) sygdomme)" : "Vælg mindst ét kapitel")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canStart ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!canStart)
                .padding()
            }
        }
    }
}

/// Selve gennemgangen: én sygdom ad gangen med tjekliste og facit.
struct ExamRecallSession: View {
    let diseases: [Disease]
    let onFinished: () -> Void

    @State private var index = 0
    @State private var revealed = false
    @State private var recalled: Set<String> = []

    private func fields(for d: Disease) -> [(title: String, icon: String, content: String)] {
        let raw: [(String, String, String)] = [
            ("Definition", "text.book.closed", d.definition),
            ("Forekomst", "person.3", d.prevalence),
            ("Patogenese", "waveform.path.ecg", d.pathogenesis),
            ("Ætiologi", "magnifyingglass", d.etiology),
            ("Symptomer", "thermometer", d.symptoms),
            ("Diagnostik", "stethoscope", d.diagnostics),
            ("Behandling", "pills", d.treatment),
            ("Følgesygdomme", "arrow.triangle.branch", d.complications ?? ""),
            ("Prognose", "chart.line.uptrend.xyaxis", d.prognosis),
            ("Byrde", "exclamationmark.triangle", d.burden),
        ]
        return raw
            .filter { !$0.2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { (title: $0.0, icon: $0.1, content: $0.2) }
    }

    var body: some View {
        if index >= diseases.count {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("Færdig!")
                    .font(.largeTitle).bold()
                Text("Du har gennemgået alle \(diseases.count) sygdomme.")
                    .foregroundColor(.secondary)
                Button("Tilbage til emner") { onFinished() }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
            }
            .padding()
        } else {
            let d = diseases[index]
            let f = fields(for: d)
            VStack(alignment: .leading, spacing: 0) {
                Text("Sygdom \(index + 1) / \(diseases.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding([.top, .horizontal])

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 12) {
                            Image(systemName: d.chapterIcon)
                                .font(.title)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(d.name).font(.title).bold()
                                Text(d.chapter).font(.subheadline).foregroundColor(.secondary)
                            }
                        }

                        if !revealed {
                            Text("Recitér af hukommelsen – kryds af, hvad du kunne huske:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            ForEach(f, id: \.title) { field in
                                Button {
                                    if recalled.contains(field.title) { recalled.remove(field.title) }
                                    else { recalled.insert(field.title) }
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: recalled.contains(field.title) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(recalled.contains(field.title) ? .green : .secondary)
                                        Image(systemName: field.icon)
                                            .foregroundColor(.blue)
                                            .frame(width: 22)
                                        Text(field.title).foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            ForEach(f, id: \.title) { field in
                                DetailSection(title: field.title, content: field.content, icon: field.icon)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()
                if !revealed {
                    Button { revealed = true } label: {
                        Text("Vis facit (\(recalled.count)/\(f.count) husket)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding()
                } else {
                    Button { next() } label: {
                        Text(index + 1 < diseases.count ? "Næste sygdom" : "Afslut")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
            }
        }
    }

    private func next() {
        revealed = false
        recalled.removeAll()
        index += 1
    }
}
