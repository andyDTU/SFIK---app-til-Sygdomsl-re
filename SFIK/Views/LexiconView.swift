import SwiftUI

struct LexiconView: View {
    let diseases: [Disease]
    @State private var searchText = ""
    @State private var highOnly = false

    var filteredDiseases: [Disease] {
        var result = diseases
        if highOnly {
            result = result.filter { DiseasePriority.tier(for: $0) == .high }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.chapter.localizedCaseInsensitiveContains(searchText) }
        }
        return result
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
        VStack(spacing: 0) {
            Picker("Filter", selection: $highOnly) {
                Text("Alle").tag(false)
                Text("⭐ Høj prioritet").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

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
                                    Spacer()
                                    if DiseasePriority.tier(for: disease) == .high {
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
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
        }
        .navigationTitle("Sygdomsleksikon")
        .searchable(text: $searchText, prompt: "Søg efter sygdom eller kapitel")
    }
}
