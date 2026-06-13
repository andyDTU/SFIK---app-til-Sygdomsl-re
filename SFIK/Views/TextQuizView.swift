import SwiftUI

struct TextQuizView: View {
    let diseases: [Disease]
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentQuestion: TQ?
    @State private var score = 0
    @State private var questionsAnswered = 0
    @State private var userAnswer: String = ""
    @State private var showingFeedback = false
    @State private var isCorrect = false
    @State private var selectedChapters: Set<String> = []
    @State private var started = false

    struct TQ {
        let questionText: String
        let correctAnswer: String
        let propertyType: String
    }

    /// Sygdomme der må stilles spørgsmål om (valgte kapitler; tema-kort udeladt).
    private var questionPool: [Disease] {
        let pool = diseases.filter { !$0.isTopic }
        let sel = pool.filter { selectedChapters.contains($0.chapter) }
        return sel.isEmpty ? pool : sel
    }

    private var allChapters: [String] {
        Array(Set(diseases.filter { !$0.isTopic }.map { $0.chapter })).sorted()
    }

    private var allChaptersSelected: Bool { selectedChapters.count == allChapters.count }
    
    var body: some View {
        NavigationStack {
            VStack {
                if !started {
                    setupView
                } else if let tq = currentQuestion {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Spørgsmål \(questionsAnswered + 1)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Hvilken sygdom passer til følgende \(tq.propertyType)?")
                            .font(.headline)
                        
                        ScrollView {
                            Text(tq.questionText)
                                .font(.title3)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.platformSecondaryBackground)
                                .cornerRadius(10)
                        }
                        .frame(maxHeight: 200)
                        
                        Spacer()
                        
                        if !showingFeedback {
                            TextField("Skriv sygdommens navn her...", text: $userAnswer)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disableAutocorrection(true)
                            
                            Button("Tjek Svar") {
                                checkAnswer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(isCorrect ? "Korrekt!" : "Forkert!")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(isCorrect ? .green : .red)
                                
                                if !isCorrect {
                                    Text("Dit svar: \(userAnswer)")
                                        .foregroundColor(.secondary)
                                    Text("Rigtigt svar: \(tq.correctAnswer)")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                                
                                Button("Næste Spørgsmål") {
                                    generateQuestion()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.top)
                            }
                            .padding()
                            .background(Color.platformBackground)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isCorrect ? Color.green : Color.red, lineWidth: 2))
                        }
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(started ? "Score: \(score) / \(questionsAnswered)" : "Skriftlig Quiz")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if started {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { resetToSetup() } label: { Label("Emner", systemImage: "chevron.left") }
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Luk") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                if selectedChapters.isEmpty { selectedChapters = Set(allChapters) }
            }
        }
    }
    
    // MARK: - Startskærm (emne-vælger)

    private var setupView: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(allChapters, id: \.self) { ch in
                        Button { toggle(ch) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedChapters.contains(ch) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedChapters.contains(ch) ? .blue : .secondary)
                                Text(ch).foregroundColor(.primary)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack {
                        Text("Vælg sygdomsemner")
                        Spacer()
                        Button(allChaptersSelected ? "Fravælg alle" : "Vælg alle") {
                            selectedChapters = allChaptersSelected ? [] : Set(allChapters)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                    }
                } footer: {
                    Text("Du får én sygdom ad gangen og skal selv skrive navnet. Spørgsmålene stilles kun om de valgte emner.")
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif

            VStack(spacing: 0) {
                Divider()
                Button { start() } label: {
                    Text(selectedChapters.isEmpty ? "Vælg mindst ét emne" : "Start (\(questionPool.count) sygdomme)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedChapters.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(selectedChapters.isEmpty)
                .padding()
            }
        }
    }

    private func toggle(_ ch: String) {
        if selectedChapters.contains(ch) { selectedChapters.remove(ch) }
        else { selectedChapters.insert(ch) }
    }

    private func start() {
        started = true
        score = 0
        questionsAnswered = 0
        generateQuestion()
    }

    private func resetToSetup() {
        started = false
        currentQuestion = nil
        showingFeedback = false
        userAnswer = ""
    }

    private func generateQuestion() {
        guard !questionPool.isEmpty else { return }

        let correctDisease = questionPool.randomElement()!
        
        let properties = [
            ("symptomer", correctDisease.symptoms),
            ("definition", correctDisease.definition),
            ("diagnostik", correctDisease.diagnostics),
            ("patogenese", correctDisease.pathogenesis)
        ]
        
        let validProperties = properties.filter { !$0.1.isEmpty }
        guard let selectedProperty = validProperties.randomElement() else {
            generateQuestion()
            return
        }
        
        // Skjul sygdommens navn + afslørende beslægtede ord (delt logik i Redactor).
        let questionText = Redactor.redact(name: correctDisease.name, in: selectedProperty.1)

        showingFeedback = false
        userAnswer = ""
        isCorrect = false
        
        currentQuestion = TQ(
            questionText: questionText,
            correctAnswer: correctDisease.name,
            propertyType: selectedProperty.0
        )
    }
    
    private func checkAnswer() {
        guard let tq = currentQuestion else { return }
        
        let userClean = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correctClean = tq.correctAnswer.lowercased()
        
        // Tillad delvist match eller hvis brugeren skriver det meste rigtigt (meget grov kontrol)
        // For at gøre det retfærdigt, tjekker vi om brugerens svar er en del af navnet eller omvendt.
        if correctClean.contains(userClean) && userClean.count > 4 {
            isCorrect = true
        } else if userClean == correctClean {
            isCorrect = true
        } else {
            isCorrect = false
        }
        
        showingFeedback = true
        questionsAnswered += 1
        if isCorrect {
            score += 1
        }
    }
}
