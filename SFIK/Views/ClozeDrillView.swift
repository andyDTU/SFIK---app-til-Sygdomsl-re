import SwiftUI

/// Tal- & medicin-drill: auto-genererede udfyld-hullet-kort fra de strukturerede
/// felter (forekomst-tal, procenter, blodtryk, lægemidler).
struct ClozeDrillView: View {
    let diseases: [Disease]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedChapters: Set<String> = []
    @State private var session: [ClozeItem]? = nil

    private var allChapters: [String] {
        Array(Set(diseases.filter { !$0.isTopic }.map { $0.chapter })).sorted()
    }

    private var itemCount: Int {
        ClozeGenerator.items(for: diseases, chapters: selectedChapters).count
    }

    private var canStart: Bool { !selectedChapters.isEmpty && itemCount > 0 }

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    ClozeDrillSession(items: session) { self.session = nil }
                } else {
                    selectionScreen
                }
            }
            .navigationTitle(session == nil ? "Tal & medicin" : "Drill")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if session != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { session = nil } label: {
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
                    Text("Genererer udfyld-hullet-kort med de tal og lægemidler, der er nemme at glemme. Recitér svaret, og afslør så facit.")
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
                    session = ClozeGenerator.items(for: diseases, chapters: selectedChapters)
                } label: {
                    Text(canStart ? "Start (\(itemCount) kort)" : "Vælg kapitler med tal/medicin")
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

/// Selve drillen: ét cloze-kort ad gangen med selvbedømmelse.
struct ClozeDrillSession: View {
    let items: [ClozeItem]
    let onFinished: () -> Void

    @State private var index = 0
    @State private var revealed = false
    @State private var correct = 0

    var body: some View {
        if index >= items.count {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("Færdig!")
                    .font(.largeTitle).bold()
                Text("Du svarede rigtigt på \(correct) ud af \(items.count).")
                    .foregroundColor(.secondary)
                Button("Tilbage til emner") { onFinished() }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
            }
            .padding()
        } else {
            let item = items[index]
            VStack(alignment: .leading, spacing: 0) {
                Text("Kort \(index + 1) / \(items.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding([.top, .horizontal])

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Text(item.diseaseName).font(.headline)
                            Text("· \(item.fieldLabel)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Text(item.prompt)
                            .font(.title3)
                            .fixedSize(horizontal: false, vertical: true)

                        if revealed {
                            Divider()
                            HStack(spacing: 8) {
                                Image(systemName: "key.fill").foregroundColor(.green)
                                Text("Svar: ")
                                    .foregroundColor(.secondary)
                                + Text(item.answer).bold()
                            }
                            .font(.title3)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()
                if !revealed {
                    Button { revealed = true } label: {
                        Text("Vis svar")
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
                    HStack(spacing: 14) {
                        Button { advance(gotIt: false) } label: {
                            Label("Forkert", systemImage: "xmark")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)

                        Button { advance(gotIt: true) } label: {
                            Label("Rigtig", systemImage: "checkmark")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                }
            }
        }
    }

    private func advance(gotIt: Bool) {
        if gotIt { correct += 1 }
        revealed = false
        index += 1
    }
}
