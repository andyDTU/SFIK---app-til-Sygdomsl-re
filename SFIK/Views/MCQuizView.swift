import SwiftUI

struct MCQuizView: View {
    let diseases: [Disease]

    @Environment(\.presentationMode) var presentationMode

    @State private var difficulty: Difficulty? = nil
    @State private var currentQuestion: MCQ?
    @State private var score = 0
    @State private var questionsAnswered = 0
    @State private var selectedAnswer: String? = nil
    @State private var isAnswerCorrect: Bool = false
    @State private var showingFeedback = false
    @State private var diseaseToRead: Disease? = nil
    @State private var selectedChapters: Set<String> = []

    enum Difficulty { case easy, hard }

    struct MCQ {
        let prompt: String          // Spørgsmåls-overskrift
        let body: String?           // Evt. tekstboks (fx symptom-tekst); nil hvis svarene selv er tekster
        let options: [String]
        let correctAnswer: String
        let correctDisease: Disease // Til "Læs om sygdommen"
    }

    /// Alle egentlige sygdomskort (tema-kort udelades). Bruges til distraktorer.
    private var allPool: [Disease] { diseases.filter { !$0.isTopic } }

    /// Sygdomme der må stilles spørgsmål OM (de valgte kapitler).
    private var questionPool: [Disease] {
        let sel = allPool.filter { selectedChapters.contains($0.chapter) }
        return sel.isEmpty ? allPool : sel
    }

    private var allChapters: [String] {
        Array(Set(allPool.map { $0.chapter })).sorted()
    }

    private var allChaptersSelected: Bool { selectedChapters.count == allChapters.count }

    var body: some View {
        NavigationStack {
            Group {
                if difficulty == nil {
                    setupView
                } else if let mcq = currentQuestion {
                    questionView(mcq)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(difficulty == nil ? "Multiple Choice" : "Score: \(score) / \(questionsAnswered)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if difficulty != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { resetToSetup() } label: { Label("Emner", systemImage: "chevron.left") }
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Luk") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .onAppear { if selectedChapters.isEmpty { selectedChapters = Set(allChapters) } }
        }
        .sheet(item: $diseaseToRead) { disease in
            NavigationStack {
                DiseaseDetailView(disease: disease)
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Button("Luk") { diseaseToRead = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Startskærm (emner + sværhedsgrad)

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
                    Text("Spørgsmålene stilles kun om de valgte emner. Svær: forkerte svar tages fra samme kapitel (sværere at skelne); Let: fra andre kapitler.")
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif

            VStack(spacing: 10) {
                Divider()
                Text(selectedChapters.isEmpty
                     ? "Vælg mindst ét emne"
                     : "Vælg sværhedsgrad for at starte (\(questionPool.count) sygdomme)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    Button { start(.easy) } label: {
                        levelLabel(title: "Let", subtitle: "Andre kapitler", color: .green)
                    }
                    .buttonStyle(.plain)
                    Button { start(.hard) } label: {
                        levelLabel(title: "Svær", subtitle: "Samme kapitel", color: .orange)
                    }
                    .buttonStyle(.plain)
                }
                .disabled(selectedChapters.isEmpty)
                .opacity(selectedChapters.isEmpty ? 0.5 : 1)
            }
            .padding()
        }
    }

    private func toggle(_ ch: String) {
        if selectedChapters.contains(ch) { selectedChapters.remove(ch) }
        else { selectedChapters.insert(ch) }
    }

    private func resetToSetup() {
        difficulty = nil
        currentQuestion = nil
        showingFeedback = false
        selectedAnswer = nil
    }

    private func levelLabel(title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.headline)
            Text(subtitle).font(.caption)
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(color)
        .cornerRadius(12)
    }

    private func start(_ level: Difficulty) {
        difficulty = level
        score = 0
        questionsAnswered = 0
        generateQuestion()
    }

    // MARK: - Spørgsmålsvisning

    private func questionView(_ mcq: MCQ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Spørgsmål \(questionsAnswered + 1)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(mcq.prompt)
                    .font(.headline)

                if let body = mcq.body {
                    Text(body)
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.platformSecondaryBackground)
                        .cornerRadius(10)
                }

                ForEach(mcq.options, id: \.self) { option in
                    Button {
                        handleAnswer(option: option, correctAnswer: mcq.correctAnswer)
                    } label: {
                        HStack(alignment: .top) {
                            Text(option)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer(minLength: 8)
                            if showingFeedback {
                                if option == mcq.correctAnswer {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                } else if option == selectedAnswer {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(getButtonColor(option: option, correctAnswer: mcq.correctAnswer))
                        .foregroundColor(showingFeedback && (option == mcq.correctAnswer || option == selectedAnswer) ? .white : .primary)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    }
                    .disabled(showingFeedback)
                }

                if showingFeedback {
                    // Ved forkert svar: tilbud om at læse om sygdommen (uden at forlade quizzen)
                    if !isAnswerCorrect {
                        Button {
                            diseaseToRead = mcq.correctDisease
                        } label: {
                            Label("Læs om \(mcq.correctDisease.name)", systemImage: "book")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.platformSecondaryBackground)
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                        }
                    }

                    Button("Næste Spørgsmål") {
                        generateQuestion()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }

    private func handleAnswer(option: String, correctAnswer: String) {
        selectedAnswer = option
        isAnswerCorrect = (option == correctAnswer)
        showingFeedback = true
        questionsAnswered += 1
        if isAnswerCorrect { score += 1 }
    }

    private func getButtonColor(option: String, correctAnswer: String) -> Color {
        guard showingFeedback else { return Color.platformBackground }
        if option == correctAnswer { return .green }
        else if option == selectedAnswer { return .red }
        return Color.platformBackground
    }

    // MARK: - Spørgsmålsgenerering

    private enum Mode: CaseIterable { case classic, reverse, negative, prevalence }

    private func generateQuestion() {
        guard allPool.count >= 4 else { return }
        showingFeedback = false
        selectedAnswer = nil

        // Prøv tilfældige typer indtil én kan bygges med tilgængelige data.
        for _ in 0..<25 {
            let mode = Mode.allCases.randomElement()!
            let correct = questionPool.randomElement()!
            if let mcq = build(mode: mode, correct: correct) {
                currentQuestion = mcq
                return
            }
        }
        // Fald tilbage til klassisk på definition (findes altid).
        if let any = questionPool.randomElement() {
            currentQuestion = MCQ(
                prompt: "Hvilken sygdom passer til følgende definition?",
                body: redactName(of: any, in: any.definition),
                options: nameOptions(correct: any),
                correctAnswer: any.name,
                correctDisease: any
            )
        }
    }

    private func build(mode: Mode, correct: Disease) -> MCQ? {
        switch mode {
        case .classic:    return buildClassic(correct)
        case .prevalence: return buildPrevalence(correct)
        case .reverse:    return buildReverse(correct)
        case .negative:   return buildNegative(correct)
        }
    }

    // Egenskab → sygdom
    private func buildClassic(_ correct: Disease) -> MCQ? {
        let props: [(String, String)] = [
            ("symptomer", correct.symptoms), ("definition", correct.definition),
            ("diagnostik", correct.diagnostics), ("patogenese", correct.pathogenesis),
            ("behandling", correct.treatment), ("ætiologi (årsag)", correct.etiology),
            ("prognose", correct.prognosis)
        ].filter { !$0.1.isEmpty }
        guard let (label, text) = props.randomElement() else { return nil }
        return MCQ(
            prompt: "Hvilken sygdom passer til følgende \(label)?",
            body: redactName(of: correct, in: text),
            options: nameOptions(correct: correct),
            correctAnswer: correct.name,
            correctDisease: correct
        )
    }

    // Forekomst/tal → sygdom
    private func buildPrevalence(_ correct: Disease) -> MCQ? {
        guard !correct.prevalence.isEmpty else { return nil }
        return MCQ(
            prompt: "Hvilken sygdom har følgende forekomst?",
            body: redactName(of: correct, in: correct.prevalence),
            options: nameOptions(correct: correct),
            correctAnswer: correct.name,
            correctDisease: correct
        )
    }

    // Sygdom → vælg den korrekte egenskab-tekst
    private func buildReverse(_ correct: Disease) -> MCQ? {
        let fields: [(String, KeyPath<Disease, String>)] = [
            ("symptomer", \.symptoms), ("behandling", \.treatment),
            ("definition", \.definition), ("diagnostik", \.diagnostics)
        ]
        for (label, kp) in fields.shuffled() {
            let correctText = correct[keyPath: kp]
            guard !correctText.isEmpty else { continue }
            let others = distractorDiseases(for: correct) { !$0[keyPath: kp].isEmpty }
            guard others.count >= 3 else { continue }
            let correctOpt = snippet(redactName(of: correct, in: correctText))
            // Saml unikke distraktorer, forskellige fra det korrekte svar
            var seen: Set<String> = [correctOpt]
            var distinct: [String] = []
            for d in others {
                let s = snippet(redactName(of: d, in: d[keyPath: kp]))
                if !seen.contains(s) { seen.insert(s); distinct.append(s) }
            }
            guard distinct.count >= 3 else { continue }
            var options = Array(distinct.prefix(3))
            options.append(correctOpt)
            options.shuffle()
            return MCQ(
                prompt: "Hvilke(n) \(label) passer til \(correct.name)?",
                body: nil,
                options: options,
                correctAnswer: correctOpt,
                correctDisease: correct
            )
        }
        return nil
    }

    // 3 sande udsagn om sygdommen + 1 fremmed udsagn → find det der IKKE passer
    private func buildNegative(_ correct: Disease) -> MCQ? {
        let ownFields = [correct.symptoms, correct.definition, correct.diagnostics, correct.treatment, correct.prognosis]
        var trueStatements = ownFields
            .flatMap { sentences($0) }
            .map { redactName(of: correct, in: $0) }
        trueStatements = Array(Set(trueStatements)).filter { $0.count >= 15 }
        guard trueStatements.count >= 3 else { return nil }
        trueStatements.shuffle()

        // Fremmed udsagn fra en anden sygdom (samme/andet kapitel afhængig af niveau)
        let foreignSource = distractorDiseases(for: correct) {
            !$0.symptoms.isEmpty || !$0.definition.isEmpty
        }
        guard let foreign = foreignSource.first else { return nil }
        let foreignSentences = (sentences(foreign.symptoms) + sentences(foreign.definition))
            .map { redactName(of: foreign, in: redactName(of: correct, in: $0)) }
            .filter { $0.count >= 15 }
        guard let foreignStatement = foreignSentences.randomElement() else { return nil }

        // Tre unikke sande udsagn
        var seen = Set<String>()
        var trueOpts: [String] = []
        for s in trueStatements.map({ snippet($0) }) {
            if !seen.contains(s) { seen.insert(s); trueOpts.append(s) }
            if trueOpts.count == 3 { break }
        }
        guard trueOpts.count == 3 else { return nil }

        let foreignOpt = snippet(foreignStatement)
        guard !seen.contains(foreignOpt) else { return nil }
        var options = trueOpts
        options.append(foreignOpt)
        options.shuffle()

        return MCQ(
            prompt: "Hvilket udsagn passer IKKE til \(correct.name)?",
            body: nil,
            options: options,
            correctAnswer: foreignOpt,
            correctDisease: correct
        )
    }

    // MARK: - Hjælpere

    /// 4 svarmuligheder som sygdomsnavne (korrekt + 3 distraktorer efter niveau).
    private func nameOptions(correct: Disease) -> [String] {
        var options = distractorDiseases(for: correct) { _ in true }.prefix(3).map { $0.name }
        options.append(correct.name)
        options.shuffle()
        return options
    }

    /// Distraktor-sygdomme ordnet efter sværhedsgrad.
    private func distractorDiseases(for correct: Disease, matching requirement: (Disease) -> Bool) -> [Disease] {
        let same = allPool.filter { $0.chapter == correct.chapter && $0.id != correct.id && requirement($0) }.shuffled()
        let other = allPool.filter { $0.chapter != correct.chapter && $0.id != correct.id && requirement($0) }.shuffled()
        // Svær: prioritér samme kapitel (svært at skelne). Let: prioritér andre kapitler.
        return difficulty == .hard ? (same + other) : (other + same)
    }

    /// Forkort lange svartekster, så svar-knapperne forbliver overskuelige.
    private func snippet(_ text: String, max: Int = 400) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count <= max { return t }
        let idx = t.index(t.startIndex, offsetBy: max)
        return String(t[..<idx]).trimmingCharacters(in: .whitespaces) + "…"
    }

    /// Del en tekst i sætninger (til negative spørgsmål).
    private func sentences(_ text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        return text
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count >= 15 && $0.count <= 160 }
    }

    /// Slører navnet + afslørende beslægtede ord (fælles delt logik i Redactor).
    private func redactName(of disease: Disease, in text: String) -> String {
        Redactor.redact(name: disease.name, in: text)
    }
}
