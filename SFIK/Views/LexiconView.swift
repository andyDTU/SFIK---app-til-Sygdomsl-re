import SwiftUI

struct LexiconView: View {
    let diseases: [Disease]
    @State private var searchText = ""

    var filteredDiseases: [Disease] {
        if searchText.isEmpty {
            return diseases
        } else {
            return diseases.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.chapter.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var groupedDiseases: [String: [Disease]] {
        Dictionary(grouping: filteredDiseases, by: { $0.chapter })
    }

    var body: some View {
        #if os(macOS)
        lexiconContent
        #else
        NavigationView {
            lexiconContent
        }
        #endif
    }

    private var lexiconContent: some View {
        List {
            ForEach(groupedDiseases.keys.sorted(), id: \.self) { chapter in
                Section(header: Text(chapter)) {
                    ForEach(groupedDiseases[chapter] ?? []) { disease in
                        NavigationLink(destination: DiseaseDetailView(disease: disease)) {
                            HStack {
                                Image(systemName: disease.chapterIcon)
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                Text(disease.name)
                                    .font(.headline)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(InsetGroupedListStyle())
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Sygdomsleksikon")
        .searchable(text: $searchText, prompt: "Søg efter sygdom eller kapitel")
    }
}
