import Foundation
import Combine

/// Bedømmelse af et kort efter genkaldelse (Leitner-stil).
enum ReviewGrade: Equatable {
    case again   // Kunne ikke huske → tilbage til boks 1
    case hard    // Med besvær → bliv i boksen
    case good    // Husket → ét trin op
    case easy    // Sad lige i skabet → to trin op
}

/// Vedvarende repetitionstilstand for ét kort (gemmes på disk).
struct CardReviewState: Codable {
    var box: Int           // Leitner-boks 1...5
    var dueDate: Date      // Næste gang kortet er forfaldent
    var lastReviewed: Date?

    var isMastered: Bool { box >= 5 }
}

/// Ægte spaced repetition: husker hvert korts boks og forfaldsdato på tværs af
/// app-sessioner (gemt i UserDefaults som JSON). Delt singleton, så både
/// flashcard-træning og en evt. fremtidig oversigt kan læse samme data.
final class SpacedRepetitionStore: ObservableObject {
    static let shared = SpacedRepetitionStore()

    @Published private(set) var states: [String: CardReviewState] = [:]

    /// Antal sammenhængende dage med mindst én repetition.
    @Published private(set) var streak: Int = 0
    private var lastStudyDay: Date?

    private let storageKey = "sfik.srs.states.v1"
    private let streakKey = "sfik.srs.streak.v1"
    private let lastDayKey = "sfik.srs.lastday.v1"

    private init() { load() }

    // MARK: - Opslag

    func state(for key: String) -> CardReviewState? { states[key] }

    func box(for key: String) -> Int { states[key]?.box ?? 1 }

    /// Et kort er forfaldent, hvis det aldrig er set, eller dueDate er passeret.
    func isDue(_ key: String, now: Date = Date()) -> Bool {
        guard let s = states[key] else { return true }
        return s.dueDate <= now
    }

    /// Sorteringsdato: nye (usete) kort først, derefter mest forfaldne.
    func sortDate(for key: String) -> Date {
        states[key]?.dueDate ?? .distantPast
    }

    func dueCount(among keys: [String], now: Date = Date()) -> Int {
        keys.filter { isDue($0, now: now) }.count
    }

    func masteredCount(among keys: [String]) -> Int {
        keys.filter { states[$0]?.isMastered == true }.count
    }

    // MARK: - Mutationer

    /// Leitner-intervaller i dage per boks (1...5).
    private func intervalDays(forBox box: Int) -> Int {
        switch box {
        case 1: return 1
        case 2: return 2
        case 3: return 4
        case 4: return 8
        default: return 16
        }
    }

    func grade(_ key: String, _ grade: ReviewGrade, now: Date = Date()) {
        let current = states[key]?.box ?? 1
        let newBox: Int
        let addDays: Int
        switch grade {
        case .again:
            newBox = 1
            addDays = 0            // forfalden igen med det samme
        case .hard:
            newBox = max(1, current)
            addDays = 1
        case .good:
            newBox = min(5, current + 1)
            addDays = intervalDays(forBox: min(5, current + 1))
        case .easy:
            newBox = min(5, current + 2)
            addDays = intervalDays(forBox: min(5, current + 2))
        }
        let due = Calendar.current.date(byAdding: .day, value: addDays, to: now) ?? now
        states[key] = CardReviewState(box: newBox, dueDate: due, lastReviewed: now)
        recordStudy(now: now)
        save()
    }

    /// Opdaterer streak ved første repetition på en ny dag.
    private func recordStudy(now: Date) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        if let last = lastStudyDay {
            let lastDay = cal.startOfDay(for: last)
            if today == lastDay { return }   // allerede talt i dag
            if let nextDay = cal.date(byAdding: .day, value: 1, to: lastDay), nextDay == today {
                streak += 1                  // i går → fortsæt streak
            } else {
                streak = 1                   // hul i streaken → start forfra
            }
        } else {
            streak = 1
        }
        lastStudyDay = today
        UserDefaults.standard.set(streak, forKey: streakKey)
        UserDefaults.standard.set(today, forKey: lastDayKey)
    }

    /// Nulstil repetitionstilstand for et sæt kort (fx ved "Start forfra").
    func reset(keys: [String]) {
        for k in keys { states[k] = nil }
        save()
    }

    // MARK: - Persistens

    private func load() {
        streak = UserDefaults.standard.integer(forKey: streakKey)
        lastStudyDay = UserDefaults.standard.object(forKey: lastDayKey) as? Date
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: CardReviewState].self, from: data)
        else { return }
        states = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(states) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
