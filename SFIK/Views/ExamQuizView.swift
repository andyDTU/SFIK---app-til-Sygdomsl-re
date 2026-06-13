import SwiftUI

struct ExamQuestion: Codable, Identifiable {
    let id = UUID()
    let examSet: String
    let diseaseIds: [String]
    let question: String
    let answer: String
}

struct ExamQuizView: View {
    let examQuestions: [ExamQuestion]
    
    @Environment(\.presentationMode) var presentationMode
    @State private var currentIndex = 0
    @State private var showAnswer = false
    @State private var userAnswer = ""
    @State private var score = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                if examQuestions.isEmpty {
                    Text("Ingen eksamensspørgsmål tilgængelige.")
                } else if currentIndex >= examQuestions.count {
                    VStack(spacing: 20) {
                        Text("Godt klaret!")
                            .font(.largeTitle)
                            .bold()
                        Text("Du har været igennem alle \(examQuestions.count) spørgsmål.")
                        Text("Din score: \(score)")
                        Button("Start forfra") {
                            currentIndex = 0
                            score = 0
                            showAnswer = false
                            userAnswer = ""
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                } else {
                    let q = examQuestions[currentIndex]
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Kilde: \(q.examSet)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("Spørgsmål \(currentIndex + 1) af \(examQuestions.count)")
                            .font(.headline)
                        
                        Text(q.question)
                            .font(.title3)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        
                        if !showAnswer {
                            TextField("Skriv dit bud her...", text: $userAnswer, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(5...10)
                            
                            Button("Se Modelbesvarelse") {
                                showAnswer = true
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(userAnswer.isEmpty)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Dit svar:")
                                    .font(.subheadline)
                                Text(userAnswer)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                
                                Text("Modelbesvarelse:")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                Text(q.answer)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(10)
                                
                                Text("Hvordan klarede du den?")
                                    .font(.headline)
                                    .padding(.top)
                                
                                HStack {
                                    Button("Helt forkert") { nextQuestion(correct: false) }
                                        .buttonStyle(EvalButtonStyle(color: .red))
                                    Button("Næsten") { nextQuestion(correct: true) }
                                        .buttonStyle(EvalButtonStyle(color: .orange))
                                    Button("Pletskud") {
                                        score += 1
                                        nextQuestion(correct: true)
                                    }
                                        .buttonStyle(EvalButtonStyle(color: .green))
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Eksamens-simulator")
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
        }
    }
    
    private func nextQuestion(correct: Bool) {
        // Hvis forkert kunne man smide den bag i køen her. For nu går vi bare videre.
        withAnimation {
            userAnswer = ""
            showAnswer = false
            currentIndex += 1
        }
    }
}

struct EvalButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.5 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}
