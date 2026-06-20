import SwiftUI

struct ExamFocusView: View {
    let diseases: [Disease]

    // Primær fokus (orange)
    private var primary: [Disease] {
        diseases
            .filter { DiseasePriority.tier(for: $0) == .high && !$0.isTopic }
            .sorted { $0.chapter == $1.chapter ? $0.name < $1.name : $0.chapter < $1.chapter }
    }

    // Sekundær fokus (blå)
    private var secondaryDiseases: [Disease] {
        diseases
            .filter { DiseasePriority.tier(for: $0) == .secondary && !$0.isTopic }
            .sorted { $0.chapter == $1.chapter ? $0.name < $1.name : $0.chapter < $1.chapter }
    }

    // Alle i fokus — bruges til træningsværktøjerne
    private var focus: [Disease] { primary + secondaryDiseases }

    // MARK: Sheet-state
    @State private var showingFlashcards      = false
    @State private var showingMCQuiz          = false
    @State private var showingTextQuiz        = false
    @State private var showingExamSimulator   = false
    @State private var showingComparison      = false
    @State private var showingExamRecall      = false
    @State private var showingClozeDrill      = false
    @State private var showingPatternCards    = false
    @State private var showingDistinguisher   = false
    @State private var showingDiseaseWeb      = false
    @State private var selectedDisease: Disease? = nil
    @State private var showingDashboard       = false

    @ObservedObject private var store = SpacedRepetitionStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                diseaseSection
                Divider()
                trainingSection
            }
            .padding()
        }
        #if os(macOS)
        .navigationTitle("Eksamenstræning")
        #else
        .navigationBarTitle("Eksamenstræning", displayMode: .large)
        #endif
        // MARK: Sheets
        .sheet(isPresented: $showingFlashcards) {
            FlashcardTopicSelectionView(diseases: focus).trainingSheetFrame()
        }
        .sheet(isPresented: $showingMCQuiz) {
            MCQuizView(diseases: focus).trainingSheetFrame()
        }
        .sheet(isPresented: $showingTextQuiz) {
            TextQuizView(diseases: focus).trainingSheetFrame()
        }
        .sheet(isPresented: $showingExamSimulator) {
            ExamQuizView(examQuestions: loadExamQuestions()).trainingSheetFrame()
        }
        .sheet(isPresented: $showingComparison) {
            ComparisonView(diseases: focus).trainingSheetFrame()
        }
        .sheet(isPresented: $showingExamRecall) {
            ExamRecallView(diseases: focus).trainingSheetFrame()
        }
        .sheet(isPresented: $showingClozeDrill) {
            ClozeDrillView(diseases: focus).trainingSheetFrame()
        }
        .sheet(isPresented: $showingPatternCards) {
            PatternFlashcardView(diseases: focus).trainingSheetFrame()
        }
        .sheet(isPresented: $showingDistinguisher) {
            DistinguisherView(diseases: focus).trainingSheetFrame()
        }
        .sheet(isPresented: $showingDiseaseWeb) {
            DiseaseWebView(diseases: focus).trainingSheetFrame()
        }
        .sheet(isPresented: $showingDashboard) {
            ProgressDashboardView(diseases: focus).trainingSheetFrame()
        }
        .sheet(item: $selectedDisease) { disease in
            NavigationStack {
                DiseaseDetailView(disease: disease)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Luk") { selectedDisease = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        let keys = focus.flatMap { $0.flashcardKeys }
        let due  = store.dueCount(among: keys)
        let pct  = keys.isEmpty ? 0 : Int((Double(store.masteredCount(among: keys)) / Double(keys.count) * 100).rounded())

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "graduationcap.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Eksamenstræning")
                        .font(.title2.bold())
                    Text("\(primary.count) primære · \(secondaryDiseases.count) sekundære · \(focus.count) i alt")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Fremdrifts-banner
            Button { showingDashboard = true } label: {
                HStack(spacing: 0) {
                    statPill(value: "\(due)",    label: "forfaldne",  icon: "clock.badge.checkmark", color: .blue)
                    Divider().frame(height: 36)
                    statPill(value: "\(pct) %",  label: "mestret",    icon: "checkmark.seal.fill",   color: .green)
                    Divider().frame(height: 36)
                    statPill(value: "\(store.streak)", label: "streak", icon: "flame.fill",           color: .orange)
                    Image(systemName: "chevron.right")
                        .font(.footnote).foregroundColor(.secondary)
                        .padding(.trailing, 4)
                }
                .padding(.vertical, 12)
                .background(Color.platformSecondaryBackground)
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
    }

    private func statPill(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundColor(color)
                Text(value).font(.headline)
            }
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sygdomsoversigt

    private var chapters: [String] {
        Array(Set(focus.map { $0.chapter })).sorted()
    }

    private var diseaseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            diseaseLayer(
                title: "⭐ PRIMÆR FOKUS",
                subtitle: "\(primary.count) sygdomme — sikreste eksamensemner",
                diseases: primary,
                color: .orange
            )
            diseaseLayer(
                title: "SEKUNDÆR FOKUS",
                subtitle: "\(secondaryDiseases.count) sygdomme — tænk bredt",
                diseases: secondaryDiseases,
                color: .blue
            )
        }
    }

    private func diseaseLayer(title: String, subtitle: String, diseases: [Disease], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .tracking(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            let chaps = Array(Set(diseases.map { $0.chapter })).sorted()
            ForEach(chaps, id: \.self) { chapter in
                let rows = diseases.filter { $0.chapter == chapter }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Image(systemName: rows.first?.chapterIcon ?? "book")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(chapter)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    FlowLayout(spacing: 6) {
                        ForEach(rows) { disease in
                            Button { selectedDisease = disease } label: {
                                Text(disease.name.components(separatedBy: " (").first ?? disease.name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(color.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(color.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding()
        .background(color.opacity(0.04))
        .cornerRadius(12)
    }

    // MARK: - Træningsknapper

    private var trainingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TRÆN MED DISSE SYGDOMME")
                .font(.caption.bold())
                .foregroundColor(.orange)
                .tracking(1)

            #if os(macOS)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                trainingButtons
            }
            #else
            VStack(spacing: 14) { trainingButtons }
            #endif
        }
    }

    @ViewBuilder
    private var trainingButtons: some View {
        Button { showingFlashcards = true } label: {
            TrainingCard(title: "Flashcards",
                         description: "Spaced repetition kun på de \(focus.count) eksamensrelevante sygdomme.",
                         icon: "rectangle.stack.fill", color: .orange)
        }
        Button { showingExamRecall = true } label: {
            TrainingCard(title: "Eksamens-genkaldelse",
                         description: "Recitér alle felter for én sygdom ad gangen — eksamensformat.",
                         icon: "brain.head.profile", color: .teal)
        }
        Button { showingClozeDrill = true } label: {
            TrainingCard(title: "Tal & medicin",
                         description: "Tal, procenter og lægemidler for eksamens-sygdommene.",
                         icon: "number.square.fill", color: .pink)
        }
        Button { showingMCQuiz = true } label: {
            TrainingCard(title: "Multiple Choice",
                         description: "Auto-genererede MCQ-spørgsmål filtreret til eksamenspulje.",
                         icon: "list.bullet.rectangle", color: .purple)
        }
        Button { showingTextQuiz = true } label: {
            TrainingCard(title: "Skriftlig Quiz",
                         description: "Skriv sygdomsnavnet selv — kun eksamensrelevante.",
                         icon: "keyboard.fill", color: .red)
        }
        Button { showingExamSimulator = true } label: {
            TrainingCard(title: "Eksamens-simulator",
                         description: "Ægte eksamensopgaver fra tidligere år.",
                         icon: "graduationcap.fill", color: .green)
        }
        Button { showingComparison = true } label: {
            TrainingCard(title: "Sammenlign (vs.)",
                         description: "Stil eksamens-sygdomme op side om side.",
                         icon: "rectangle.split.2x1", color: .indigo)
        }
        Button { showingPatternCards = true } label: {
            TrainingCard(title: "Bro-kort",
                         description: "Tværgående mønstre og fælles træk — kun eksamensfeltet.",
                         icon: "link.circle.fill", color: .cyan)
        }
        Button { showingDistinguisher = true } label: {
            TrainingCard(title: "Fælles / Unikt",
                         description: "Skeln forvekslingspar fra eksamens-sygdommene.",
                         icon: "arrow.left.arrow.right.circle.fill", color: .mint)
        }
        Button { showingDiseaseWeb = true } label: {
            TrainingCard(title: "Sygdomsweb",
                         description: "Udforsk forbindelserne mellem eksamens-sygdommene.",
                         icon: "point.3.connected.trianglepath.dotted", color: .blue)
        }
    }

    // MARK: - Hjælper

    private func loadExamQuestions() -> [ExamQuestion] {
        guard let url = Bundle.main.url(forResource: "exam_questions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let qs = try? JSONDecoder().decode([ExamQuestion].self, from: data) else { return [] }
        return qs
    }
}
