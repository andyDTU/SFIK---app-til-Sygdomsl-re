import SwiftUI

/// ThemeClusterView: browse sygdomme grupperet efter tværgående temaer.
/// Visualiserer broer mellem sygdomme — se hvilke der deler behandling,
/// genetik, patogenese, etc.
struct ThemeClusterView: View {
    let diseases: [Disease]
    @Environment(\.presentationMode) var presentationMode

    @State private var clusters: [ThemeCluster] = []
    @State private var selectedCluster: ThemeCluster? = nil
    @State private var selectedDisease: Disease? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if clusters.isEmpty {
                        emptyView
                    } else {
                        ForEach(clusters) { cluster in
                            clusterCard(cluster)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Tema-klynger")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Luk") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
        .onAppear {
            if clusters.isEmpty {
                clusters = PatternGenerator.themeClusters(from: diseases)
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

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tema-klynger")
                .font(.largeTitle)
                .bold()
            Text("Sygdomme grupperet efter delte træk. Tryk på en klynge for at udfolde den.")
                .foregroundColor(.secondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "circle.grid.2x2")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("Ingen klynger fundet")
                .font(.title3)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }

    private func clusterCard(_ cluster: ThemeCluster) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title + description
            HStack(spacing: 10) {
                Image(systemName: "network")
                    .font(.title2)
                    .foregroundColor(.indigo)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cluster.title)
                        .font(.title3)
                        .bold()
                    Text(cluster.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(cluster.diseases.count)")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.indigo)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.indigo.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Keywords
            FlowLayout(spacing: 8) {
                ForEach(cluster.keywords, id: \.self) { kw in
                    Text(kw)
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.indigo.opacity(0.08))
                        .foregroundColor(.indigo)
                        .clipShape(Capsule())
                }
            }

            Divider()

            // Disease chips
            FlowLayout(spacing: 8) {
                ForEach(cluster.diseases) { disease in
                    Button {
                        selectedDisease = disease
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: disease.chapterIcon)
                                .font(.caption)
                            Text(disease.name)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.platformSecondaryBackground)
                        .foregroundColor(.primary)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(16)
    }
}

// MARK: - FlowLayout helper (wraps chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    ThemeClusterView(diseases: [])
}
