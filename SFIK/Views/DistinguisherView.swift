import SwiftUI

/// Distinguisher: "Hvad er fælles / Hvad er unikt?"
/// Træner evnen til at skelne mellem to lignende sygdomme.
/// Hvert spørgsmål viser et udsagn — brugeren skal vælge om det gælder
/// sygdom A, sygdom B, begge, eller ingen af dem.
struct DistinguisherView: View {
    let diseases: [Disease]
    @Environment(\.presentationMode) var presentationMode

    @State private var pairs: [DistinguisherPair] = []
    @State private var index = 0
    @State private var showingFeedback = false
    @State private var currentQuestion: DistinguisherQuestion? = nil
    @State private var selectedAnswer: DistinguisherAnswer? = nil
    @State private var score = 0
    @State private var questionsInRound = 0

    private enum DistinguisherAnswer: String, CaseIterable {
        case both = "Begge"
        case onlyA = "Kun A"
        case onlyB = "Kun B"
        case neither = "Ingen"
    }

    private struct DistinguisherQuestion: Identifiable {
        let id = UUID()
        let statement: String
        let correct: DistinguisherAnswer
        let explanation: String
    }

    var body: some View {
        NavigationStack {
            Group {
                if pairs.isEmpty {
                    emptyView
                } else if index >= pairs.count {
                    completionView
                } else {
                    quizView
                }
            }
            .navigationTitle("Forvekslingstræner")
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
            if pairs.isEmpty {
                pairs = PatternGenerator.distinguisherPairs(from: diseases)
            }
        }
    }

    // MARK: - Subviews

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.split.2x1")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("Ingen par fundet")
                .font(.title3)
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
            Text("Score: \(score) / \(questionsInRound)")
                .foregroundColor(.secondary)

            Button("Start forfra") {
                index = 0
                score = 0
                questionsInRound = 0
                pairs.shuffle()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var quizView: some View {
        let pair = pairs[index]

        // Build questions on first appearance of this pair
        let questions = questionsFor(pair: pair)

        return VStack(spacing: 0) {
            // Header with pair name
            HStack(spacing: 12) {
                Text(pair.diseaseA.name)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                Text("vs.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(pair.diseaseB.name)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if currentQuestion == nil {
                        Text("Hvad er fælles? Hvad er unikt?")
                            .font(.title2)
                            .bold()

                        Text("Tryk på en af knapperne nedenfor for at starte.")
                            .foregroundColor(.secondary)

                        Button("Start med dette par") {
                            currentQuestion = questions.first
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.top)
                    } else if let q = currentQuestion {
                        // Progress
                        HStack {
                            Text("Par \(index + 1) / \(pairs.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Score: \(score)")
                                .font(.subheadline)
                                .bold()
                        }

                        // Question statement
                        Text(q.statement)
                            .font(.title3)
                            .bold()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.platformSecondaryBackground)
                            .cornerRadius(12)

                        // Answer buttons
                        if !showingFeedback {
                            VStack(spacing: 12) {
                                ForEach(DistinguisherAnswer.allCases, id: \.rawValue) { answer in
                                    Button {
                                        selectedAnswer = answer
                                        checkAnswer(question: q, answer: answer)
                                    } label: {
                                        Text(answer.rawValue)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.platformSecondaryBackground)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                            .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            feedbackView(question: q)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func feedbackView(question: DistinguisherQuestion) -> some View {
        let isCorrect = selectedAnswer == question.correct

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
                Text(isCorrect ? "Korrekt!" : "Forkert")
                    .font(.headline)
                    .foregroundColor(isCorrect ? .green : .red)
                Spacer()
            }

            Text(question.explanation)
                .font(.body)

            Button("Næste") {
                advanceQuestion()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(12)
    }

    // MARK: - Logic

    private func questionsFor(pair: DistinguisherPair) -> [DistinguisherQuestion] {
        var questions: [DistinguisherQuestion] = []

        // Add common traits (answer: both)
        for trait in pair.commonTraits.prefix(2) {
            questions.append(DistinguisherQuestion(
                statement: trait,
                correct: .both,
                explanation: "Dette er et fælles træk mellem \(pair.diseaseA.name) og \(pair.diseaseB.name)."
            ))
        }

        // Add unique A traits (answer: onlyA)
        for trait in pair.uniqueA.prefix(2) {
            questions.append(DistinguisherQuestion(
                statement: trait,
                correct: .onlyA,
                explanation: "Dette gælder kun \(pair.diseaseA.name), ikke \(pair.diseaseB.name)."
            ))
        }

        // Add unique B traits (answer: onlyB)
        for trait in pair.uniqueB.prefix(2) {
            questions.append(DistinguisherQuestion(
                statement: trait,
                correct: .onlyB,
                explanation: "Dette gælder kun \(pair.diseaseB.name), ikke \(pair.diseaseA.name)."
            ))
        }

        // Add a distractor from another disease (answer: neither)
        let otherDisease = diseases.filter { $0.id != pair.diseaseA.id && $0.id != pair.diseaseB.id && !$0.isTopic }.randomElement()
        if let other = otherDisease {
            let fields = [
                other.definition, other.pathogenesis, other.etiology,
                other.symptoms, other.treatment, other.diagnostics
            ].filter { !$0.isEmpty }.randomElement()
            if let field = fields {
                questions.append(DistinguisherQuestion(
                    statement: field,
                    correct: .neither,
                    explanation: "Dette gælder \(other.name), hverken \(pair.diseaseA.name) eller \(pair.diseaseB.name)."
                ))
            }
        }

        return questions.shuffled()
    }

    private func checkAnswer(question: DistinguisherQuestion, answer: DistinguisherAnswer) {
        showingFeedback = true
        questionsInRound += 1
        if answer == question.correct {
            score += 1
        }
    }

    private func advanceQuestion() {
        showingFeedback = false
        selectedAnswer = nil
        currentQuestion = nil
        index += 1
    }
}

#Preview {
    DistinguisherView(diseases: [])
}
