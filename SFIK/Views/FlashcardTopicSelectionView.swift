import SwiftUI

struct FlashcardTopicSelectionView: View {
    let diseases: [Disease]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedChapters: Set<String> = []
    @State private var selectedCategories: Set<String> = []
    @State private var trainingCards: [Flashcard]? = nil
    @State private var direction: FlashcardDirection = .produce
    @State private var onlyDue: Bool = true

    @ObservedObject private var store = SpacedRepetitionStore.shared

    /// Kategorierne (felterne) der kan trænes — i fast rækkefølge.
    private let allCategories = [
        "Definition", "Forekomst", "Patogenese & Ætiologi", "Symptomer & Fund",
        "Diagnostik", "Behandling & Forebyggelse", "Følgesygdomme", "Prognose", "Byrde"
    ]

    private var allChapters: [String] {
        Array(Set(diseases.map { $0.chapter })).sorted()
    }

    private var canStart: Bool {
        !selectedChapters.isEmpty && !selectedCategories.isEmpty && cardCount > 0
    }

    private var startButtonLabel: String {
        if cardCount == 0 {
            return onlyDue ? "Ingen forfaldne kort 🎉" : "Vælg emner for at starte"
        }
        return "Start træning (\(cardCount) kort)"
    }

    var body: some View {
        NavigationStack {
            Group {
                if let cards = trainingCards {
                    FlashcardView(flashcards: cards)
                } else {
                    selectionScreen
                }
            }
            .navigationTitle(trainingCards == nil ? "Vælg emner" : "Flashcards")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if trainingCards != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            trainingCards = nil
                        } label: {
                            Label("Emner", systemImage: "chevron.left")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Luk") { dismiss() }
                }
            }
            .onAppear {
                if selectedChapters.isEmpty { selectedChapters = Set(allChapters) }
                if selectedCategories.isEmpty { selectedCategories = Set(allCategories) }
            }
        }
    }

    // MARK: - Emnevalg

    private var selectionScreen: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    Picker("Retning", selection: $direction) {
                        Text("Genkald indhold").tag(FlashcardDirection.produce)
                        Text("Genkend sygdom").tag(FlashcardDirection.identify)
                    }
                    #if os(iOS)
                    .pickerStyle(.segmented)
                    #endif

                    Toggle("Kun forfaldne i dag", isOn: $onlyDue)

                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(.blue)
                        Text("Forfaldne nu: \(dueCount)")
                        Spacer()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                } header: {
                    Text("Træningsform")
                } footer: {
                    Text(direction == .produce
                         ? "Genkald indhold: du ser sygdom + felt og skal huske indholdet (eksamensretningen)."
                         : "Genkend sygdom: du ser et felts indhold og skal gætte sygdommen.")
                }

                Section {
                    ForEach(allCategories, id: \.self) { category in
                        selectionRow(title: category, isSelected: selectedCategories.contains(category)) {
                            if selectedCategories.contains(category) { selectedCategories.remove(category) }
                            else { selectedCategories.insert(category) }
                        }
                    }
                } header: {
                    sectionHeader("Kategorier (hvad vil du øve?)",
                                  allSelected: selectedCategories.count == allCategories.count) {
                        if selectedCategories.count == allCategories.count { selectedCategories.removeAll() }
                        else { selectedCategories = Set(allCategories) }
                    }
                }

                Section {
                    ForEach(allChapters, id: \.self) { chapter in
                        selectionRow(title: chapter, isSelected: selectedChapters.contains(chapter)) {
                            if selectedChapters.contains(chapter) { selectedChapters.remove(chapter) }
                            else { selectedChapters.insert(chapter) }
                        }
                    }
                } header: {
                    sectionHeader("Kapitler",
                                  allSelected: selectedChapters.count == allChapters.count) {
                        if selectedChapters.count == allChapters.count { selectedChapters.removeAll() }
                        else { selectedChapters = Set(allChapters) }
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif

            // Bundbjælke med start-knap
            VStack(spacing: 0) {
                Divider()
                Button {
                    startTraining()
                } label: {
                    Text(startButtonLabel)
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

    private func selectionRow(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String, allSelected: Bool, toggleAll: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button(allSelected ? "Fravælg alle" : "Vælg alle", action: toggleAll)
                .buttonStyle(.plain)
                .foregroundColor(.blue)
        }
    }

    // MARK: - Handlinger

    private func startTraining() {
        trainingCards = buildFlashcards()
    }

    /// Alle valgte kort (kapitler × kategorier), uafhængigt af forfald.
    private func candidateCards() -> [Flashcard] {
        var cards: [Flashcard] = []
        for d in diseases where selectedChapters.contains(d.chapter) {
            for entry in d.flashcardEntries where selectedCategories.contains(entry.category) {
                cards.append(Flashcard(disease: d, category: entry.category,
                                       content: entry.content, direction: direction))
            }
        }
        return cards
    }

    /// Kort til selve sessionen: evt. kun forfaldne, og sorteret så nye/mest
    /// forfaldne kort kommer først (spaced repetition).
    private func sessionCards() -> [Flashcard] {
        var cards = candidateCards()
        if onlyDue { cards = cards.filter { store.isDue($0.key) } }
        return cards.sorted { store.sortDate(for: $0.key) < store.sortDate(for: $1.key) }
    }

    /// Antal kort i den kommende session.
    private var cardCount: Int { sessionCards().count }

    /// Samlet antal forfaldne kort blandt det valgte (uanset "kun forfaldne").
    private var dueCount: Int {
        store.dueCount(among: candidateCards().map { $0.key })
    }

    private func buildFlashcards() -> [Flashcard] {
        sessionCards()
    }
}
