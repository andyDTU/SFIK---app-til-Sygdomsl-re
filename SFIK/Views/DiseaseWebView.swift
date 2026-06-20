import SwiftUI

// MARK: - Entry: søg og vælg startpunkt

struct DiseaseWebView: View {
    let diseases: [Disease]
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""

    private var pool: [Disease] { diseases.filter { !$0.isTopic } }

    private var chapters: [String] {
        Array(Set(pool.map { $0.chapter })).sorted()
    }

    private func diseases(in chapter: String) -> [Disease] {
        pool.filter { $0.chapter == chapter }.sorted { $0.name < $1.name }
    }

    private var searchResults: [Disease] {
        pool.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    // Kapitel-grupperet oversigt
                    ForEach(chapters, id: \.self) { chapter in
                        Section(chapter) {
                            ForEach(diseases(in: chapter)) { disease in
                                NavigationLink(value: disease) {
                                    diseaseRow(disease)
                                }
                            }
                        }
                    }
                } else {
                    ForEach(searchResults) { disease in
                        NavigationLink(value: disease) {
                            diseaseRow(disease)
                        }
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .searchable(text: $searchText, prompt: "Søg efter sygdom…")
            .navigationTitle("Sygdomsweb")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Luk") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .navigationDestination(for: Disease.self) { disease in
                DiseaseNodeView(disease: disease, allDiseases: diseases)
            }
            .safeAreaInset(edge: .bottom) {
                hintBar
            }
        }
    }

    private var hintBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .foregroundColor(.blue)
            Text("Vælg en sygdom for at se dens forbindelser til andre sygdomme")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    private func diseaseRow(_ disease: Disease) -> some View {
        HStack(spacing: 10) {
            Image(systemName: disease.chapterIcon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(disease.name)
                    .font(.body)
                let n = ConnectionStore.shared.connections(for: disease.id).count
                Text(n == 0 ? "Ingen forbindelser" : "\(n) forbindelser")
                    .font(.caption)
                    .foregroundColor(n == 0 ? .secondary.opacity(0.5) : .secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Sygdomsknude: alle forbindelser for én sygdom

struct DiseaseNodeView: View {
    let disease: Disease
    let allDiseases: [Disease]

    private var myConnections: [DiseaseConnection] {
        ConnectionStore.shared.connections(for: disease.id)
    }

    private let typeOrder = [
        "komplikation", "progression", "mekanisme", "forveksles", "risikofaktor", "behandling"
    ]

    private var grouped: [(type: String, connections: [DiseaseConnection])] {
        var dict: [String: [DiseaseConnection]] = [:]
        for c in myConnections { dict[c.type, default: []].append(c) }
        return typeOrder.compactMap { t in
            guard let conns = dict[t] else { return nil }
            return (type: t, connections: conns)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                definitionCard
                ForEach(grouped, id: \.type) { group in
                    connectionSection(group)
                }
                if grouped.isEmpty {
                    Text("Ingen registrerede forbindelser for denne sygdom endnu.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle(disease.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: Definition-kort øverst

    private var definitionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("DEFINITION", systemImage: "text.quote")
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .tracking(0.8)
            Text(firstSentence(disease.definition))
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(12)
    }

    // MARK: Forbindelses-sektion

    private func connectionSection(_ group: (type: String, connections: [DiseaseConnection])) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: typeIcon(group.type))
                    .foregroundColor(typeColor(group.type))
                Text(typeLabel(group.type).uppercased())
                    .font(.caption.bold())
                    .foregroundColor(typeColor(group.type))
                    .tracking(0.8)
                Text("(\(group.connections.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(group.connections) { conn in
                let otherID = conn.otherID(from: disease.id)
                if let other = allDiseases.first(where: { $0.id == otherID }) {
                    NavigationLink(value: other) {
                        connectionCard(disease: other, bridge: conn.bridge, type: group.type)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func connectionCard(disease: Disease, bridge: String, type: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(disease.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Text(bridge)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 3)
        }
        .padding()
        .background(typeColor(type).opacity(0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(typeColor(type).opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: Hjælpere

    private func firstSentence(_ text: String) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let r = t.range(of: ". ") { return String(t[t.startIndex..<r.lowerBound]) }
        return t.count > 150 ? String(t.prefix(147)) + "…" : t
    }

    private func typeLabel(_ type: String) -> String {
        switch type {
        case "komplikation":  return "Komplikationer"
        case "mekanisme":     return "Fælles mekanisme"
        case "forveksles":    return "Forveksles med"
        case "risikofaktor":  return "Delte risikofaktorer"
        case "progression":   return "Progression"
        case "behandling":    return "Fælles behandling"
        default:              return type
        }
    }

    private func typeIcon(_ type: String) -> String {
        switch type {
        case "komplikation":  return "arrow.right.circle.fill"
        case "mekanisme":     return "link.circle.fill"
        case "forveksles":    return "arrow.left.arrow.right.circle.fill"
        case "risikofaktor":  return "exclamationmark.triangle.fill"
        case "progression":   return "arrow.up.right.circle.fill"
        case "behandling":    return "pills.fill"
        default:              return "circle.fill"
        }
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "komplikation":  return .red
        case "mekanisme":     return .purple
        case "forveksles":    return .orange
        case "risikofaktor":  return .brown
        case "progression":   return .blue
        case "behandling":    return .green
        default:              return .gray
        }
    }
}
