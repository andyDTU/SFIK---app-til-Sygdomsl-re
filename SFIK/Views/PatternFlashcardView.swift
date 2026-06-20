import SwiftUI

/// Bro-kort: tværgående mønster-quiz. Lær hvilke sygdomme der deler behandling,
/// genetik, patogenese, risikofaktorer mm. Opbygger klynger i hukommelsen.
struct PatternFlashcardView: View {
    let diseases: [Disease]
    @Environment(\.presentationMode) var presentationMode

    @State private var patterns: [PatternItem] = []
    @State private var index = 0
    @State private var selected: Set<String> = []
    @State private var showingFeedback = false
    @State private var isCorrect = false
    @State private var categoryFilter: PatternCategory? = nil

    private var filteredPatterns: [PatternItem] {
        if let cat = categoryFilter {
            return patterns.filter { $0.category == cat }
        }
        return patterns
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredPatterns.isEmpty {
                    emptyView
                } else if index >= filteredPatterns.count {
                    completionView
                } else {
                    quizView
                }
            }
            .navigationTitle("Bro-kort")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Luk") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
        .onAppear {
            if patterns.isEmpty {
                patterns = PatternGenerator.generatePatterns(from: diseases)
            }
        }
    }

    // MARK: - Subviews

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "network")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("Ingen mønstre fundet")
                .font(.title3)
            Text("Tjek at dine sygdomsdata er indlæst.")
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            Text("Færdig!")
                .font(.largeTitle).bold()
            Text("Du har gennemgået alle \(filteredPatterns.count) bro-kort.")
                .foregroundColor(.secondary)

            Button("Start forfra") {
                index = 0
                selected.removeAll()
                showingFeedback = false
                patterns.shuffle()
            }
            .buttonStyle(.borderedProminent)

            Button("Tilbage") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var quizView: some View {
        let item = filteredPatterns[index]

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Progress + category badge
                HStack {
                    Text("Kort \(index + 1) / \(filteredPatterns.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: item.category.icon)
                        Text(item.category.rawValue)
                    }
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(item.category.color.opacity(0.15))
                    .foregroundColor(item.category.color)
                    .clipShape(Capsule())
                }

                // Question
                Text(item.question)
                    .font(.title2)
                    .bold()

                // Clue
                Text(item.clue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Options grid
                let allOptions = (item.answer + item.distractors).shuffled()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(allOptions, id: \.self) { option in
                        optionButton(option: option, item: item)
                    }
                }

                // Feedback
                if showingFeedback {
                    feedbackBlock(item: item)
                }

                Spacer(minLength: 20)

                // Action button
                if !showingFeedback {
                    Button("Tjek svar") {
                        checkAnswer(item: item)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selected.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
                    .disabled(selected.isEmpty)
                } else {
                    Button("Næste kort") {
                        nextCard()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    private func optionButton(option: String, item: PatternItem) -> some View {
        let isSelected = selected.contains(option)
        let isAnswer = item.answer.contains(option)
        let isDistractor = item.distractors.contains(option)

        var bgColor: Color {
            if !showingFeedback { return isSelected ? Color.blue.opacity(0.15) : Color.platformSecondaryBackground }
            if isAnswer { return Color.green.opacity(0.2) }
            if isSelected && isDistractor { return Color.red.opacity(0.2) }
            return Color.platformSecondaryBackground
        }

        var borderColor: Color {
            if !showingFeedback { return isSelected ? .blue : Color.gray.opacity(0.3) }
            if isAnswer { return .green }
            if isSelected && isDistractor { return .red }
            return Color.gray.opacity(0.3)
        }

        return Button {
            if !showingFeedback {
                if isSelected { selected.remove(option) } else { selected.insert(option) }
            }
        } label: {
            HStack {
                Text(option)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if showingFeedback {
                    if isAnswer {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    }
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                }
            }
            .padding()
            .background(bgColor)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 2))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func feedbackBlock(item: PatternItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
                Text(isCorrect ? "Korrekt!" : "Ikke helt rigtig")
                    .font(.headline)
                    .foregroundColor(isCorrect ? .green : .red)
                Spacer()
            }

            if !isCorrect {
                Text("Korrekte svar:")
                    .font(.subheadline).bold()
                ForEach(item.answer, id: \.self) { a in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark").foregroundColor(.green)
                        Text(a).font(.body)
                    }
                }
            }

            Text("\(item.answer.count) sygdomme deler dette træk.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func checkAnswer(item: PatternItem) {
        let correctSet = Set(item.answer)
        isCorrect = selected == correctSet
        showingFeedback = true
    }

    private func nextCard() {
        index += 1
        selected.removeAll()
        showingFeedback = false
    }
}

// MARK: - Preview helpers

#Preview {
    PatternFlashcardView(diseases: [])
}
