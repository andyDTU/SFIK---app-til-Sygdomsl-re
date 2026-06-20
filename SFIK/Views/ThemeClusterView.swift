import SwiftUI

struct ThemeClusterView: View {
    let diseases: [Disease]
    @Environment(\.presentationMode) var presentationMode

    @State private var clusters: [ThemeCluster] = []
    @State private var expandedClusters: Set<String> = []
    @State private var selectedDisease: Disease? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
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

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tema-klynger")
                .font(.largeTitle).bold()
            Text("Tryk på en klynge for at se hvad der binder sygdommene — og hvad der adskiller dem.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 4)
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

    // MARK: - Cluster card

    private func clusterCard(_ cluster: ThemeCluster) -> some View {
        let isExpanded = expandedClusters.contains(cluster.id)

        return VStack(alignment: .leading, spacing: 0) {

            // ── Header row (always visible) ──────────────────────────
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded { expandedClusters.remove(cluster.id) }
                    else          { expandedClusters.insert(cluster.id) }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: cluster.icon)
                        .font(.title2)
                        .foregroundColor(cluster.color)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(cluster.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(cluster.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text("\(cluster.diseases.count)")
                        .font(.subheadline.bold())
                        .foregroundColor(cluster.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(cluster.color.opacity(0.12))
                        .clipShape(Capsule())

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .buttonStyle(.plain)

            // ── Expanded content ─────────────────────────────────────
            if isExpanded {
                Divider().padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {

                    // Fælles / bro
                    VStack(alignment: .leading, spacing: 8) {
                        Label("FÆLLES", systemImage: "link")
                            .font(.caption2.bold())
                            .foregroundColor(cluster.color)
                            .tracking(0.8)

                        FlowLayout(spacing: 6) {
                            ForEach(cluster.keywords, id: \.self) { kw in
                                Text(kw)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 3)
                                    .background(cluster.color.opacity(0.1))
                                    .foregroundColor(cluster.color)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Divider()

                    // Adskiller sig — én linje per sygdom
                    VStack(alignment: .leading, spacing: 0) {
                        Label("ADSKILLER SIG", systemImage: "arrow.triangle.branch")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                            .tracking(0.8)
                            .padding(.bottom, 10)

                        ForEach(Array(cluster.diseases.enumerated()), id: \.element.id) { idx, disease in
                            Button {
                                selectedDisease = disease
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: disease.chapterIcon)
                                        .font(.caption)
                                        .foregroundColor(cluster.color)
                                        .frame(width: 16)
                                        .padding(.top, 2)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(disease.name)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.primary)
                                        Text(definitionSnippet(disease))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.tertiary)
                                }
                                .padding(.vertical, 9)
                            }
                            .buttonStyle(.plain)

                            if idx < cluster.diseases.count - 1 {
                                Divider().padding(.leading, 26)
                            }
                        }
                    }
                }
                .padding([.horizontal, .bottom])
                .padding(.top, 12)
            }
        }
        .background(Color.platformSecondaryBackground)
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private func definitionSnippet(_ disease: Disease) -> String {
        let text = disease.definition.trimmingCharacters(in: .whitespacesAndNewlines)
        // Take first sentence (up to first ". " or end of string)
        if let range = text.range(of: ". ") {
            let sentence = String(text[text.startIndex..<range.lowerBound])
            return sentence.count > 120 ? String(sentence.prefix(117)) + "…" : sentence
        }
        return text.count > 120 ? String(text.prefix(117)) + "…" : text
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + result.positions[index].x,
                            y: bounds.minY + result.positions[index].y),
                proposal: .unspecified
            )
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
                let sz = subview.sizeThatFits(.unspecified)
                if x + sz.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                x += sz.width + spacing
                lineHeight = max(lineHeight, sz.height)
            }
            size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    ThemeClusterView(diseases: [])
}
