import SwiftUI

@main
struct SFIKApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .commands {
            SFIKWindowCommands()
        }
        #endif

        #if os(macOS)
        WindowGroup("Flashcards – Alle sygdomme", id: "flashcards") {
            FlashcardsWindowView(focusOnly: false)
        }
        .defaultSize(width: 760, height: 820)

        WindowGroup("Flashcards – Eksamens­fokus", id: "examflashcards") {
            FlashcardsWindowView(focusOnly: true)
        }
        .defaultSize(width: 760, height: 820)

        WindowGroup("Spickseddel", id: "cheatsheet") {
            CheatSheetView()
                .frame(minWidth: 500, minHeight: 600)
        }
        .defaultSize(width: 700, height: 800)

        WindowGroup("Taleagtige kort", id: "speechcards") {
            SpeechCardsWindowView()
        }
        .defaultSize(width: 720, height: 880)
        #endif
    }
}

#if os(macOS)
private struct FlashcardsWindowView: View {
    @StateObject private var dataLoader = DataLoader()
    let focusOnly: Bool

    private var diseases: [Disease] {
        let all = dataLoader.diseases.filter { !$0.isTopic }
        guard focusOnly else { return all }
        return all.filter {
            DiseasePriority.tier(for: $0) == .high ||
            DiseasePriority.tier(for: $0) == .secondary
        }
    }

    var body: some View {
        FlashcardTopicSelectionView(diseases: diseases)
            .frame(minWidth: 640, minHeight: 680)
    }
}

private struct SpeechCardsWindowView: View {
    @StateObject private var dataLoader = DataLoader()

    var body: some View {
        SpeechCardView(diseases: dataLoader.diseases)
            .frame(minWidth: 640, minHeight: 720)
    }
}

struct SFIKWindowCommands: Commands {
    var body: some Commands {
        CommandMenu("Vinduer") {
            SFIKWindowMenuItem(windowID: "examflashcards", label: "Åbn Eksamens-flashcards (45 syg.)",
                               shortcut: "f", modifiers: [.command, .shift])
            SFIKWindowMenuItem(windowID: "flashcards",     label: "Åbn Flashcards – Alle sygdomme",
                               shortcut: "a", modifiers: [.command, .shift])
            SFIKWindowMenuItem(windowID: "cheatsheet",     label: "Åbn Spickseddel i nyt vindue",
                               shortcut: "s", modifiers: [.command, .shift])
            SFIKWindowMenuItem(windowID: "speechcards",    label: "Åbn Taleagtige kort i nyt vindue",
                               shortcut: "t", modifiers: [.command, .shift])
        }
    }
}

private struct SFIKWindowMenuItem: View {
    @Environment(\.openWindow) private var openWindow
    let windowID: String
    let label: String
    let shortcut: Character
    let modifiers: EventModifiers

    var body: some View {
        Button(label) { openWindow(id: windowID) }
            .keyboardShortcut(KeyEquivalent(shortcut), modifiers: modifiers)
    }
}

struct OpenWindowButton: View {
    @Environment(\.openWindow) private var openWindow
    let id: String
    let icon: String
    let tooltip: String

    var body: some View {
        Button {
            openWindow(id: id)
        } label: {
            Label(tooltip, systemImage: icon)
                .labelStyle(.iconOnly)
        }
        .help(tooltip)
    }
}
#endif
