import SwiftUI

struct MainTabView: View {
    @StateObject private var dataLoader = DataLoader()

    #if os(macOS)
    enum Tab: Hashable { case training, lexicon, prevalence, cheatsheet, glossary, reading }
    @State private var selection: Tab? = .training
    #endif

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List(selection: $selection) {
                Label("Træning", systemImage: "brain.head.profile")
                    .tag(Tab.training)
                Label("Leksikon", systemImage: "text.book.closed")
                    .tag(Tab.lexicon)
                Label("Forekomster", systemImage: "chart.bar.fill")
                    .tag(Tab.prevalence)
                Label("Spickseddel", systemImage: "note.text")
                    .tag(Tab.cheatsheet)
                Label("Ordliste", systemImage: "character.book.closed")
                    .tag(Tab.glossary)
                Label("Pensum", systemImage: "doc.richtext")
                    .tag(Tab.reading)
            }
            .navigationTitle("SFIK")
            .navigationSplitViewColumnWidth(min: 160, ideal: 200)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    OpenWindowButton(id: "flashcards",
                                     icon: "rectangle.stack.fill",
                                     tooltip: "Åbn Flashcards i nyt vindue")
                    OpenWindowButton(id: "cheatsheet",
                                     icon: "note.text",
                                     tooltip: "Åbn Spickseddel i nyt vindue")
                }
            }
        } detail: {
            NavigationStack {
                switch selection ?? .training {
                case .training:
                    TrainingView(diseases: dataLoader.diseases)
                case .lexicon:
                    LexiconView(diseases: dataLoader.diseases)
                case .prevalence:
                    PrevalenceView(diseases: dataLoader.diseases)
                case .cheatsheet:
                    CheatSheetView()
                case .glossary:
                    OrdlisteView()
                case .reading:
                    ReadingMaterialView()
                }
            }
        }
        .accentColor(.blue)
        #else
        TabView {
            TrainingView(diseases: dataLoader.diseases)
                .tabItem {
                    Label("Træning", systemImage: "brain.head.profile")
                }
            LexiconView(diseases: dataLoader.diseases)
                .tabItem {
                    Label("Leksikon", systemImage: "text.book.closed")
                }
            PrevalenceView(diseases: dataLoader.diseases)
                .tabItem {
                    Label("Forekomster", systemImage: "chart.bar.fill")
                }
            CheatSheetView()
                .tabItem {
                    Label("Spickseddel", systemImage: "note.text")
                }
            OrdlisteView()
                .tabItem {
                    Label("Ordliste", systemImage: "character.book.closed")
                }
            ReadingMaterialView()
                .tabItem {
                    Label("Pensum", systemImage: "doc.richtext")
                }
        }
        .accentColor(.blue)
        #endif
    }
}

#Preview {
    MainTabView()
}
