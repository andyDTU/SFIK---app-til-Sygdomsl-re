import SwiftUI

struct SimilarityView: View {
    let diseases: [Disease]
    @Environment(\.presentationMode) var presentationMode

    @State private var traits: [SimilarityTrait] = []
    @State private var selectedCategory: SimilarityCategory? = nil
    @State private var searchText = ""
    @State private var selectedDisease: Disease? = nil

    private var filtered: [SimilarityTrait] {
        var result = traits
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.keyword.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    // Grupper per kategori (bevar rækkefølgen fra SimilarityCategory.allCases)
    private var groupedTraits: [(cat: SimilarityCategory, traits: [SimilarityTrait])] {
        let cats = selectedCategory.map { [$0] } ?? SimilarityCategory.allCases
        return cats.compactMap { cat in
            let t = filtered.filter { $0.category == cat }
                            .sorted { $0.diseases.count > $1.diseases.count }
            return t.isEmpty ? nil : (cat: cat, traits: t)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Filterpicker ─────────────────────────────────
                filterBar

                // ── Indhold ──────────────────────────────────────
                if filtered.isEmpty {
                    emptyView
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24, pinnedViews: .sectionHeaders) {
                            ForEach(groupedTraits, id: \.cat) { group in
                                Section {
                                    ForEach(group.traits) { trait in
                                        traitRow(trait)
                                    }
                                } header: {
                                    categoryHeader(group.cat, count: group.traits.count)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Søg efter træk…")
            .navigationTitle("Lighedsmatrix")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Luk") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .navigationDestination(for: Disease.self) { disease in
                DiseaseDetailView(disease: disease)
            }
        }
        .onAppear {
            if traits.isEmpty {
                traits = SimilarityEngine.generate(from: diseases)
            }
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

    // MARK: - Filter-bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "Alle", icon: "square.grid.2x2", color: .secondary,
                           active: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(SimilarityCategory.allCases) { cat in
                    filterChip(label: cat.rawValue, icon: cat.icon, color: cat.color,
                               active: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.platformSecondaryBackground)
    }

    private func filterChip(label: String, icon: String, color: Color,
                             active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(active ? color.opacity(0.15) : Color.platformSecondaryBackground)
            .foregroundColor(active ? color : .secondary)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20)
                .stroke(active ? color.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Kategori-header

    private func categoryHeader(_ cat: SimilarityCategory, count: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: cat.icon)
                .foregroundColor(cat.color)
            Text(cat.rawValue)
                .font(.title3.bold())
                .foregroundColor(cat.color)
            Text("(\(count) træk)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
        .background(Color.platformBackground)
    }

    // MARK: - Enkelt-træk rad

    private func traitRow(_ trait: SimilarityTrait) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Nøgleord + antal
            HStack(spacing: 8) {
                Text(trait.keyword)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(trait.diseases.count) sygd.")
                    .font(.caption.bold())
                    .foregroundColor(trait.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(trait.category.color.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Sygdoms-chips
            FlowLayout(spacing: 6) {
                ForEach(trait.diseases) { disease in
                    Button { selectedDisease = disease } label: {
                        Text(shortName(disease.name))
                            .font(.subheadline)
                            .foregroundColor(trait.category.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(trait.category.color.opacity(0.08))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(trait.category.color.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(12)
    }

    // MARK: - Tom visning

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Ingen træk matcher søgningen")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Hjælper

    private func shortName(_ name: String) -> String {
        name.components(separatedBy: " (").first ?? name
    }
}
