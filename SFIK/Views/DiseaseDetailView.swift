import SwiftUI

struct DiseaseDetailView: View {
    let disease: Disease
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: disease.chapterIcon)
                        .font(.title)
                        .foregroundColor(.blue)
                    Text(disease.chapter)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if DiseasePriority.tier(for: disease) == .high {
                        Label("Høj prioritet", systemImage: "star.fill")
                            .font(.caption).bold()
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 5)
                
                // Content sections
                DetailSection(title: "Definition", content: disease.definition, icon: "text.book.closed")
                DetailSection(title: "Forekomst", content: disease.prevalence, icon: "person.3")
                DetailSection(title: "Patogenese", content: disease.pathogenesis, icon: "waveform.path.ecg")
                DetailSection(title: "Ætiologi (Årsag)", content: disease.etiology, icon: "magnifyingglass")
                DetailSection(title: "Symptomer", content: disease.symptoms, icon: "thermometer")
                DetailSection(title: "Diagnostik", content: disease.diagnostics, icon: "stethoscope")
                DetailSection(title: "Behandling", content: disease.treatment, icon: "pills")
                DetailSection(title: "Følgesygdomme", content: disease.complications ?? "", icon: "arrow.triangle.branch")
                DetailSection(title: "Prognose", content: disease.prognosis, icon: "chart.line.uptrend.xyaxis")
                DetailSection(title: "Byrde", content: disease.burden, icon: "exclamationmark.triangle")

                // Uddybende noter (valgfri dybde-tekst, foldet sammen som standard)
                if let details = disease.details, !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    DisclosureGroup {
                        Text(.init(details))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.blue)
                            Text("Uddybende")
                                .font(.title3)
                                .bold()
                        }
                    }
                    .padding(.bottom, 6)
                }

                // Pensum-kilde
                if let source = disease.source, !source.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "book.closed")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(source)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle(disease.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        // Spring tomme sektioner over (fx kliniske felter på tema-kort)
        if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                    Text(title)
                        .font(.title3)
                        .bold()
                }

                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.leading, 4)
                    .padding(.bottom, 10)
            }
        }
    }
}
