import SwiftUI

struct FlashcardView: View {
    @State var flashcards: [Flashcard]
    @ObservedObject private var store = SpacedRepetitionStore.shared

    @State private var isFlipped = false

    var body: some View {
        VStack {
            if flashcards.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("Fantastisk!")
                        .font(.largeTitle)
                        .bold()
                    Text("Du har gennemført alle kort i dette sæt. Tilstanden er gemt – forfaldne kort dukker op igen næste gang.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            } else {
                let card = flashcards.first!

                HStack {
                    Text("Kort tilbage: \(flashcards.count)")
                    Spacer()
                    Text("Boks \(store.box(for: card.key))/5")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding([.top, .horizontal])

                Spacer()

                ZStack {
                    cardFace(for: card, side: .front)
                        .opacity(isFlipped ? 0 : 1)

                    cardFace(for: card, side: .back)
                        .opacity(isFlipped ? 1 : 0)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
                .frame(maxWidth: 560, minHeight: 360, maxHeight: 440)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: isFlipped)
                .onTapGesture { isFlipped.toggle() }

                Spacer()

                if isFlipped {
                    gradeButtons(for: card)
                        .padding(.bottom, 30)
                        .transition(.opacity)
                } else {
                    Text("Tryk på kortet for at vende det")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 54)
                }
            }
        }
        .animation(.default, value: isFlipped)
    }

    // MARK: - Bedømmelsesknapper

    @ViewBuilder
    private func gradeButtons(for card: Flashcard) -> some View {
        HStack(spacing: 14) {
            gradeButton("Igen", systemImage: "arrow.counterclockwise", color: .red) {
                grade(card, .again)
            }
            gradeButton("Svær", systemImage: "tortoise.fill", color: .orange) {
                grade(card, .hard)
            }
            gradeButton("Godt", systemImage: "hand.thumbsup.fill", color: .blue) {
                grade(card, .good)
            }
            gradeButton("Let", systemImage: "hare.fill", color: .green) {
                grade(card, .easy)
            }
        }
        .padding(.horizontal)
    }

    private func gradeButton(_ title: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func grade(_ card: Flashcard, _ g: ReviewGrade) {
        store.grade(card.key, g)
        withAnimation {
            isFlipped = false
            guard !flashcards.isEmpty else { return }
            let current = flashcards.removeFirst()
            if g == .again {
                // Vis kortet igen senere i samme session.
                let insertIndex = min(flashcards.count, 5)
                flashcards.insert(current, at: insertIndex)
            }
        }
    }

    // MARK: - Kortsider

    private enum Side { case front, back }

    @ViewBuilder
    private func cardFace(for card: Flashcard, side: Side) -> some View {
        switch (card.direction, side) {
        case (.produce, .front):
            CardFace(title: card.disease.name,
                     subtitle: "\(card.category)?",
                     bodyText: "",
                     hint: "Genkald af hukommelsen",
                     accent: .blue,
                     isQuestion: true)
        case (.produce, .back):
            CardFace(title: card.category,
                     subtitle: card.disease.name,
                     bodyText: card.content,
                     hint: nil,
                     accent: .blue,
                     isQuestion: false)
        case (.identify, .front):
            CardFace(title: card.category,
                     subtitle: "Hvilken sygdom?",
                     bodyText: Redactor.redact(name: card.disease.name, in: card.content),
                     hint: nil,
                     accent: .gray,
                     isQuestion: true)
        case (.identify, .back):
            CardFace(title: card.disease.name,
                     subtitle: card.disease.chapter,
                     bodyText: "",
                     hint: "Kategori: \(card.category)",
                     accent: .blue,
                     isQuestion: false)
        }
    }
}

/// Generisk kortside med titel, undertitel og (valgfri) brødtekst.
struct CardFace: View {
    let title: String
    let subtitle: String
    let bodyText: String
    let hint: String?
    let accent: Color
    let isQuestion: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title2).bold()
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if !bodyText.isEmpty {
                Divider().padding(.horizontal)
                ScrollView {
                    Text(bodyText)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            if let hint {
                Spacer(minLength: 0)
                Text(hint)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isQuestion ? Color.platformBackground : accent.opacity(0.12))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}
