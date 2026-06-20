import SwiftUI

struct TrainingView: View {
    let diseases: [Disease]
    @State private var showingFlashcards = false
    @State private var showingMCQuiz = false
    @State private var showingTextQuiz = false
    @State private var showingExamSimulator = false
    @State private var showingComparison = false
    @State private var showingExamRecall = false
    @State private var showingClozeDrill = false
    @State private var showingDashboard = false
    @State private var showingPatternFlashcards = false
    @State private var showingDistinguisher = false
    @State private var showingDiseaseWeb = false
    @State private var showingSimilarity = false

    @ObservedObject private var store = SpacedRepetitionStore.shared

    var body: some View {
        #if os(macOS)
        trainingContent
            .navigationTitle("Træning")
        #else
        NavigationView {
            trainingContent
                .navigationTitle("Træning")
                .navigationBarHidden(true)
        }
        #endif
    }

    @ViewBuilder
    private var trainingContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vælg Træningsform")
                        .font(.largeTitle)
                        .bold()
                    Text("Test din viden om sygdomslære.")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                dashboardSummary

                #if os(macOS)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    trainingButtons
                }
                #else
                VStack(spacing: 20) {
                    trainingButtons
                }
                #endif
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Kompakt fremdrifts-banner øverst: forfaldne i dag, mestring og streak.
    /// Tryk åbner den fulde oversigt.
    private var dashboardSummary: some View {
        let keys = diseases.filter { !$0.isTopic }.flatMap { $0.flashcardKeys }
        let total = keys.count
        let due = store.dueCount(among: keys)
        let mastered = store.masteredCount(among: keys)
        let pct = total == 0 ? 0 : Int((Double(mastered) / Double(total) * 100).rounded())

        return Button(action: { showingDashboard = true }) {
            HStack(spacing: 0) {
                summaryStat(value: "\(due)", label: "forfaldne", icon: "clock.badge.checkmark", color: .blue)
                Divider().frame(height: 36)
                summaryStat(value: "\(pct) %", label: "mestret", icon: "checkmark.seal.fill", color: .green)
                Divider().frame(height: 36)
                summaryStat(value: "\(store.streak)", label: "streak", icon: "flame.fill", color: .orange)
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 4)
            }
            .padding(.vertical, 14)
            .background(Color.platformSecondaryBackground)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDashboard) {
            ProgressDashboardView(diseases: diseases)
                .trainingSheetFrame()
        }
    }

    private func summaryStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon).foregroundColor(color)
                Text(value).font(.headline).foregroundColor(.primary)
            }
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var trainingButtons: some View {
        Button(action: { showingFlashcards = true }) {
            TrainingCard(title: "Flashcards",
                         description: "Ægte spaced repetition: appen husker dine bokse og viser forfaldne kort igen. Vælg retning – genkald indhold eller genkend sygdom.",
                         icon: "rectangle.stack.fill",
                         color: .orange)
        }
        .sheet(isPresented: $showingFlashcards) {
            FlashcardTopicSelectionView(diseases: diseases)
                .trainingSheetFrame()
        }

        Button(action: { showingExamRecall = true }) {
            TrainingCard(title: "Eksamens-genkaldelse",
                         description: "Fri genkaldelse: få én sygdom og recitér alle felter af hukommelsen, før du afslører facit.",
                         icon: "brain.head.profile",
                         color: .teal)
        }
        .sheet(isPresented: $showingExamRecall) {
            ExamRecallView(diseases: diseases)
                .trainingSheetFrame()
        }

        Button(action: { showingClozeDrill = true }) {
            TrainingCard(title: "Tal & medicin",
                         description: "Udfyld-hullet-kort med de tal, procenter og lægemidler, der er nemmest at glemme.",
                         icon: "number.square.fill",
                         color: .pink)
        }
        .sheet(isPresented: $showingClozeDrill) {
            ClozeDrillView(diseases: diseases)
                .trainingSheetFrame()
        }

        Button(action: { showingMCQuiz = true }) {
            TrainingCard(title: "Multiple Choice",
                         description: "Test din viden med uendelige, auto-genererede spørgsmål.",
                         icon: "list.bullet.rectangle",
                         color: .purple)
        }
        .sheet(isPresented: $showingMCQuiz) {
            MCQuizView(diseases: diseases)
                .trainingSheetFrame()
        }

        Button(action: { showingTextQuiz = true }) {
            TrainingCard(title: "Skriftlig Quiz",
                         description: "Auto-genererede spørgsmål, men du skal selv skrive sygdommens navn. Sværhedsgrad: Høj.",
                         icon: "keyboard.fill",
                         color: .red)
        }
        .sheet(isPresented: $showingTextQuiz) {
            TextQuizView(diseases: diseases)
                .trainingSheetFrame()
        }

        Button(action: { showingExamSimulator = true }) {
            TrainingCard(title: "Eksamens-simulator",
                         description: "Prøv kræfter med ægte (og pensum-tjekkede) eksamensopgaver.",
                         icon: "graduationcap.fill",
                         color: .green)
        }
        .sheet(isPresented: $showingExamSimulator) {
            ExamQuizView(examQuestions: loadExamQuestions())
                .trainingSheetFrame()
        }

        Button(action: { showingComparison = true }) {
            TrainingCard(title: "Sammenlign (vs.)",
                         description: "Stil forvekslingspar op side om side, felt for felt – fx type 1 vs. type 2-diabetes.",
                         icon: "rectangle.split.2x1",
                         color: .indigo)
        }
        .sheet(isPresented: $showingComparison) {
            ComparisonView(diseases: diseases)
                .trainingSheetFrame()
        }

        Button(action: { showingPatternFlashcards = true }) {
            TrainingCard(title: "Bro-kort",
                         description: "Tværgående mønster-quiz: hvilke sygdomme deler behandling, genetik, patogenese eller risikofaktorer?",
                         icon: "link.circle.fill",
                         color: .cyan)
        }
        .sheet(isPresented: $showingPatternFlashcards) {
            PatternFlashcardView(diseases: diseases)
                .trainingSheetFrame()
        }

        Button(action: { showingDistinguisher = true }) {
            TrainingCard(title: "Fælles / Unikt",
                         description: "Et udsagn – gælder det sygdom A, B, begge eller ingen? Træner skelnen mellem forvekslingspar.",
                         icon: "arrow.left.arrow.right.circle.fill",
                         color: .mint)
        }
        .sheet(isPresented: $showingDistinguisher) {
            DistinguisherView(diseases: diseases)
                .trainingSheetFrame()
        }

        Button(action: { showingDiseaseWeb = true }) {
            TrainingCard(title: "Sygdomsweb",
                         description: "Udforsk forbindelserne mellem sygdomme. Vælg en sygdom og se hvad der binder den til alle andre.",
                         icon: "point.3.connected.trianglepath.dotted",
                         color: .blue)
        }
        .sheet(isPresented: $showingDiseaseWeb) {
            DiseaseWebView(diseases: diseases)
                .trainingSheetFrame()
        }

        Button(action: { showingSimilarity = true }) {
            TrainingCard(title: "Lighedsmatrix",
                         description: "Se hvilke sygdomme der deler diagnostik, behandling, patogenese, symptomer og mere.",
                         icon: "tablecells.fill",
                         color: .teal)
        }
        .sheet(isPresented: $showingSimilarity) {
            SimilarityView(diseases: diseases)
                .trainingSheetFrame()
        }
    }

    private func loadExamQuestions() -> [ExamQuestion] {
        guard let url = Bundle.main.url(forResource: "exam_questions", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode([ExamQuestion].self, from: data)
        } catch {
            print("Fejl ved indlæsning af eksamensspørgsmål: \(error)")
            return []
        }
    }
}

extension View {
    /// Giver træningsark en brugbar minimumsstørrelse på macOS (uden den
    /// kollapser sheets med NavigationView til en tom strimmel). No-op på iOS.
    @ViewBuilder
    func trainingSheetFrame() -> some View {
        #if os(macOS)
        self.frame(minWidth: 640, idealWidth: 760, minHeight: 680, idealHeight: 820)
        #else
        self
        #endif
    }
}

struct TrainingCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
