import SwiftUI

struct MainTabView: View {
    @StateObject private var dataLoader = DataLoader()

    #if os(macOS)
    enum Tab: Hashable { case training, lexicon, glossary, reading }
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
                Label("Ordliste", systemImage: "character.book.closed")
                    .tag(Tab.glossary)
                Label("Pensum", systemImage: "doc.richtext")
                    .tag(Tab.reading)
            }
            .navigationTitle("SFIK")
            .navigationSplitViewColumnWidth(min: 160, ideal: 200)
        } detail: {
            NavigationStack {
                switch selection ?? .training {
                case .training:
                    TrainingView(diseases: dataLoader.diseases)
                case .lexicon:
                    LexiconView(diseases: dataLoader.diseases)
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
