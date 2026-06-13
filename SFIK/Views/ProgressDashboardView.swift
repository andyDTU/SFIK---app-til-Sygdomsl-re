import SwiftUI

/// Fremdrifts-/mestringsoversigt: forfaldne kort i dag, streak og mestring per
/// kapitel. Giver spaced repetition et naturligt udgangspunkt.
struct ProgressDashboardView: View {
    let diseases: [Disease]
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = SpacedRepetitionStore.shared
    @State private var showingTrain = false

    /// Kun egentlige sygdomme (temakort tæller ikke med i fremdriften).
    private var realDiseases: [Disease] { diseases.filter { !$0.isTopic } }

    private var allKeys: [String] { realDiseases.flatMap { $0.flashcardKeys } }

    private var total: Int { allKeys.count }
    private var due: Int { store.dueCount(among: allKeys) }
    private var mastered: Int { store.masteredCount(among: allKeys) }
    private var seen: Int { allKeys.filter { store.state(for: $0) != nil }.count }

    private struct ChapterProgress: Identifiable {
        let id = UUID()
        let chapter: String
        let total: Int
        let mastered: Int
        let due: Int
    }

    private var chapterProgress: [ChapterProgress] {
        let grouped = Dictionary(grouping: realDiseases, by: { $0.chapter })
        return grouped.keys.sorted().map { chapter in
            let keys = grouped[chapter]!.flatMap { $0.flashcardKeys }
            return ChapterProgress(chapter: chapter,
                                   total: keys.count,
                                   mastered: store.masteredCount(among: keys),
                                   due: store.dueCount(among: keys))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statRow

                    Button { showingTrain = true } label: {
                        Label(due > 0 ? "Træn \(due) forfaldne kort" : "Ingen forfaldne kort lige nu",
                              systemImage: "play.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(due > 0 ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(due == 0)

                    Text("Mestring per kapitel")
                        .font(.title3).bold()
                        .padding(.top, 4)

                    ForEach(chapterProgress) { cp in
                        chapterRow(cp)
                    }
                }
                .padding()
            }
            .navigationTitle("Min fremgang")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Luk") { dismiss() }
                }
            }
            .sheet(isPresented: $showingTrain) {
                FlashcardTopicSelectionView(diseases: diseases)
                    .trainingSheetFrame()
            }
        }
    }

    private var statRow: some View {
        HStack(spacing: 12) {
            StatTile(title: "Forfaldne i dag", value: "\(due)", icon: "clock.badge.checkmark", color: .blue)
            StatTile(title: "Mestret", value: "\(percent(mastered, of: total)) %", icon: "checkmark.seal.fill", color: .green)
            StatTile(title: "Streak", value: "\(store.streak) d", icon: "flame.fill", color: .orange)
        }
    }

    private func chapterRow(_ cp: ChapterProgress) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(cp.chapter)
                    .font(.subheadline).bold()
                Spacer()
                Text("\(cp.mastered)/\(cp.total) mestret")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: Double(cp.mastered), total: Double(max(cp.total, 1)))
                .tint(.green)
            if cp.due > 0 {
                Text("\(cp.due) forfaldne")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    private func percent(_ part: Int, of whole: Int) -> Int {
        whole == 0 ? 0 : Int((Double(part) / Double(whole) * 100).rounded())
    }
}

/// Lille statistik-felt til oversigtsrækken.
struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3).bold()
                .foregroundColor(.primary)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(16)
    }
}
