import SwiftUI

struct QuizView: View {
    let diseases: [Disease]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var showScore = false
    @State private var options: [Disease] = []
    @State private var targetDisease: Disease?
    @State private var selectedAnswer: Disease? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if showScore {
                    VStack(spacing: 20) {
                        Text("Quiz slut!")
                            .font(.largeTitle)
                            .bold()
                        Text("Du fik \(score) ud af 10 rigtige.")
                            .font(.title2)
                        
                        Button("Prøv igen") {
                            resetQuiz()
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                } else if let disease = targetDisease {
                    Text("Spørgsmål \(currentQuestionIndex + 1) af 10")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    
                    ProgressView(value: Double(currentQuestionIndex), total: 10.0)
                        .padding()
                    
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Text("Hvilken sygdom passer til denne beskrivelse?")
                            .font(.headline)
                        
                        ScrollView {
                            Text(disease.definition)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.platformSecondaryBackground)
                                .cornerRadius(15)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding()
                    
                    Spacer()
                    
                    VStack(spacing: 15) {
                        ForEach(options) { option in
                            Button(action: {
                                handleAnswer(option)
                            }) {
                                Text(option.name)
                                    .font(.body)
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(backgroundColor(for: option))
                                    .foregroundColor(foregroundColor(for: option))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .disabled(selectedAnswer != nil)
                        }
                    }
                    .padding()
                    
                    if selectedAnswer != nil {
                        Button("Næste spørgsmål") {
                            nextQuestion()
                        }
                        .padding()
                        .font(.headline)
                    }
                    
                    Spacer()
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Quiz")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Luk") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                generateQuestion()
            }
        }
    }
    
    private func generateQuestion() {
        guard !diseases.isEmpty else { return }
        let shuffled = diseases.shuffled()
        targetDisease = shuffled[0]
        options = Array(shuffled.prefix(4)).shuffled()
        selectedAnswer = nil
    }
    
    private func handleAnswer(_ selected: Disease) {
        selectedAnswer = selected
        if selected.id == targetDisease?.id {
            score += 1
        }
    }
    
    private func backgroundColor(for option: Disease) -> Color {
        guard let selected = selectedAnswer else {
            return Color.platformBackground
        }
        
        if option.id == targetDisease?.id {
            return .green // Rigtigt svar bliver altid grønt
        } else if option.id == selected.id {
            return .red // Forkert svar som brugeren valgte bliver rødt
        } else {
            return Color.platformBackground
        }
    }
    
    private func foregroundColor(for option: Disease) -> Color {
        if selectedAnswer != nil && (option.id == targetDisease?.id || option.id == selectedAnswer?.id) {
            return .white
        }
        return .primary
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < 9 {
            currentQuestionIndex += 1
            generateQuestion()
        } else {
            showScore = true
        }
    }
    
    private func resetQuiz() {
        currentQuestionIndex = 0
        score = 0
        showScore = false
        generateQuestion()
    }
}
