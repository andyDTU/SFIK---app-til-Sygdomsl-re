import SwiftUI

// MARK: - Entry: liste med alle sygdomme

struct SpeechCardView: View {
    let diseases: [Disease]
    @Environment(\.presentationMode) var presentationMode
    @State private var filter: FocusTier = .all
    @State private var searchText = ""

    enum FocusTier: String, CaseIterable {
        case all       = "Alle"
        case primary   = "Primær"
        case secondary = "Sekundær"
    }

    private var pool: [Disease] {
        let base = diseases.filter { !$0.isTopic }
            .sorted { $0.chapter == $1.chapter ? $0.name < $1.name : $0.chapter < $1.chapter }

        let filtered: [Disease]
        switch filter {
        case .all:       filtered = base
        case .primary:   filtered = base.filter { DiseasePriority.tier(for: $0) == .high }
        case .secondary: filtered = base.filter { DiseasePriority.tier(for: $0) == .secondary }
        }

        guard !searchText.isEmpty else { return filtered }
        return filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter-bar
                Picker("Fokus", selection: $filter) {
                    ForEach(FocusTier.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.platformSecondaryBackground)

                // Liste
                List(Array(pool.enumerated()), id: \.element.id) { idx, disease in
                    NavigationLink(value: CardDestination(diseases: pool, index: idx)) {
                        diseaseRow(disease)
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
            }
            .searchable(text: $searchText, prompt: "Søg sygdom…")
            .navigationTitle("Taleagtige kort")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Luk") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .navigationDestination(for: CardDestination.self) { dest in
                SpeechCardDetailView(diseases: dest.diseases, startIndex: dest.index)
            }
        }
    }

    private func diseaseRow(_ disease: Disease) -> some View {
        let tier = DiseasePriority.tier(for: disease)
        let dotColor: Color = tier == .high ? .orange : tier == .secondary ? .blue : .secondary
        return HStack(spacing: 10) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(disease.name)
                    .font(.body)
                Text(disease.chapter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// Hashable wrapper for NavigationLink destination
private struct CardDestination: Hashable {
    let diseases: [Disease]
    let index: Int
    func hash(into hasher: inout Hasher) { hasher.combine(index) }
    static func == (l: Self, r: Self) -> Bool { l.index == r.index }
}

// MARK: - Detaljevisning: ét kort ad gangen

struct SpeechCardDetailView: View {
    let diseases: [Disease]
    @State private var index: Int

    init(diseases: [Disease], startIndex: Int) {
        self.diseases = diseases
        _index = State(initialValue: startIndex)
    }

    private var disease: Disease { diseases[index] }
    private var tier: Priority { DiseasePriority.tier(for: disease) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // ── Kapitel-badge ───────────────────────────────
                HStack(spacing: 6) {
                    Image(systemName: disease.chapterIcon)
                        .font(.caption)
                        .foregroundColor(tier.color)
                    Text(disease.chapter)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(index + 1) / \(diseases.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 6)

                // ── Sygdomsnavn ─────────────────────────────────
                Text(disease.name)
                    .font(.title2.bold())
                    .padding(.horizontal)
                    .padding(.bottom, 14)

                // ── Felter ──────────────────────────────────────
                cardSection("Definition",           icon: "book.fill",                   color: .indigo,
                            cues: cues(disease.definition, max: 3))
                cardSection("Forekomst",             icon: "chart.bar.fill",               color: .blue,
                            cues: prevalenceCues(disease.prevalence))
                cardSection("Patogenese & Ætiologi", icon: "waveform.path.ecg",            color: .purple,
                            cues: cues(disease.pathogenesis + ". " + disease.etiology, max: 5))
                cardSection("Symptomer",             icon: "thermometer.medium",           color: .red,
                            cues: cues(disease.symptoms, max: 6))
                cardSection("Diagnostik",            icon: "stethoscope",                  color: .teal,
                            cues: cues(disease.diagnostics, max: 5))
                cardSection("Behandling",            icon: "pills.fill",                   color: .green,
                            cues: treatmentCues(disease.treatment))
                if let comp = disease.complications, !comp.trimmingCharacters(in: .whitespaces).isEmpty {
                    cardSection("Komplikationer",    icon: "arrow.triangle.branch",        color: .orange,
                                cues: cues(comp, max: 4))
                }
                cardSection("Prognose",              icon: "chart.line.uptrend.xyaxis",    color: .gray,
                            cues: cues(disease.prognosis, max: 3))

                Spacer(minLength: 32)
            }
        }
        .navigationTitle(disease.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .safeAreaInset(edge: .bottom) {
            navBar
        }
    }

    // MARK: - Navigationsbar (bund)

    private var navBar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { if index > 0 { index -= 1 } }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Forrige")
                }
                .font(.subheadline.bold())
            }
            .disabled(index == 0)
            .buttonStyle(.plain)
            .foregroundColor(index == 0 ? .secondary : tier.color)

            Spacer()

            Text("\(index + 1) / \(diseases.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { if index < diseases.count - 1 { index += 1 } }
            } label: {
                HStack(spacing: 4) {
                    Text("Næste")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline.bold())
            }
            .disabled(index == diseases.count - 1)
            .buttonStyle(.plain)
            .foregroundColor(index == diseases.count - 1 ? .secondary : tier.color)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Kortsektion

    private func cardSection(_ title: String, icon: String, color: Color, cues: [String]) -> some View {
        guard !cues.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                // Section header
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption.bold())
                        .foregroundColor(color)
                    Text(title.uppercased())
                        .font(.caption.bold())
                        .foregroundColor(color)
                        .tracking(0.8)
                }
                .padding(.horizontal)
                .padding(.top, 14)
                .padding(.bottom, 6)

                // Cue-bullets
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(cues.enumerated()), id: \.offset) { _, cue in
                        HStack(alignment: .top, spacing: 8) {
                            Text("·")
                                .font(.subheadline.bold())
                                .foregroundColor(color)
                                .frame(width: 12)
                            Text(cue)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.leading, 4)

                Divider()
                    .padding(.horizontal)
                    .padding(.top, 10)
            }
        )
    }

    // MARK: - Cue-udtrækning

    /// Splitter kun ved ægte sætningsgrænser: ". " + stort begyndelsesbogstav.
    /// Undgår at splitte ved "pga.", "bl.a.", "fx.", "dvs.", "ca.", tal + "."
    private func splitSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        var current = ""
        let chars = Array(text)
        var i = 0
        while i < chars.count {
            current.append(chars[i])
            if chars[i] == "." && i + 2 < chars.count && chars[i + 1] == " " {
                let next = chars[i + 2]
                // Split kun hvis næste ord starter med stort bogstav
                // OG det forrige ord ikke er en forkortelse (kort ord ≤4 bogstaver)
                let lastWord = current.components(separatedBy: " ").last(where: { !$0.isEmpty }) ?? ""
                let lastWordClean = lastWord.trimmingCharacters(in: .punctuationCharacters)
                let isAbbrev = lastWordClean.count <= 4 || lastWordClean.first?.isNumber == true
                if !isAbbrev && next.isUppercase {
                    sentences.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                    current = ""
                    i += 2 // spring ". " over
                    continue
                }
            }
            i += 1
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
            sentences.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return sentences.filter { !$0.isEmpty }
    }

    /// Splitter på kommaer uden for parenteser
    private func splitByCommaOutsideParens(_ text: String) -> [String] {
        var parts: [String] = []
        var current = ""
        var depth = 0
        for ch in text {
            if ch == "(" { depth += 1 }
            else if ch == ")" { depth -= 1 }
            if ch == "," && depth == 0 {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { parts.append(trimmed) }
                current = ""
            } else {
                current.append(ch)
            }
        }
        let last = current.trimmingCharacters(in: .whitespaces)
        if !last.isEmpty { parts.append(last) }
        return parts
    }

    /// Trunkerer ved ordgrænse
    private func truncate(_ s: String, at max: Int = 88) -> String {
        guard s.count > max else { return s }
        let cut = s.prefix(max)
        if let lastSpace = cut.lastIndex(of: " "), cut.distance(from: cut.startIndex, to: lastSpace) > max / 2 {
            return String(cut[..<lastSpace]) + "…"
        }
        return String(cut) + "…"
    }

    /// Generelt feltudtræk
    private func cues(_ text: String, max maxCount: Int) -> [String] {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let cleaned = text.replacingOccurrences(of: "\n", with: " ")
                          .replacingOccurrences(of: "  ", with: " ")

        let sentences = splitSentences(cleaned)
        var chunks: [String] = []
        for sent in sentences {
            // Lang sætning: split på kommaer (men ikke inden for parenteser)
            if sent.count > 60 && sent.contains(", ") {
                let parts = splitByCommaOutsideParens(sent).filter { $0.count >= 5 }
                if parts.count >= 2 {
                    chunks.append(contentsOf: parts)
                    continue
                }
            }
            chunks.append(sent)
        }

        return chunks
            .map { c -> String in
                var s = c
                while s.hasSuffix(".") || s.hasSuffix(",") { s = String(s.dropLast()) }
                return truncate(s)
            }
            .filter { $0.count >= 5 }
            .uniqued()
            .prefix(maxCount)
            .map { $0 }
    }

    /// Behandling: kommaer og sætninger — bevar parenteser samlet
    private func treatmentCues(_ text: String) -> [String] {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let cleaned = text.replacingOccurrences(of: "\n", with: " ")

        // Split på sætningsgrænser, derefter på kommaer (uden for parenteser)
        let sentences = splitSentences(cleaned)
        var chunks: [String] = []
        for sent in sentences {
            let parts = splitByCommaOutsideParens(sent).filter { $0.count >= 4 }
            chunks.append(contentsOf: parts.isEmpty ? [sent] : parts)
        }

        return chunks
            .map { c -> String in
                var s = c
                while s.hasSuffix(".") || s.hasSuffix(",") { s = String(s.dropLast()) }
                return truncate(s)
            }
            .filter { $0.count >= 4 }
            .uniqued()
            .prefix(6)
            .map { $0 }
    }

    /// Forekomst: tal · køn · debut
    private func prevalenceCues(_ raw: String) -> [String] {
        var result: [String] = []

        // Første ægte sætning (prævalenstallet)
        let first = splitSentences(raw).first ?? ""
        if first.count >= 5 { result.append(first.trimmingCharacters(in: CharacterSet(charactersIn: "."))) }

        // Køn fra PrevalenceFacts
        let facts = PrevalenceFacts.from(raw)
        if let sex = facts.sex { result.append("\(sex.symbol) \(sex.label)") }

        // Debutalder
        if let debut = facts.debut { result.append("Debut: \(debut)") }

        // Anden sætning hvis der er mere at sige
        let sentences = splitSentences(raw)
        if sentences.count >= 2 {
            let second = sentences[1].trimmingCharacters(in: CharacterSet(charactersIn: "."))
            let alreadyCovered = result.contains { $0.lowercased().hasPrefix(second.lowercased().prefix(15)) }
            if !alreadyCovered && second.count >= 10 { result.append(second) }
        }

        return Array(result.prefix(4))
    }
}

// MARK: - Array unique helper
private extension Array where Element: Equatable {
    func uniqued() -> [Element] {
        reduce(into: []) { result, item in
            if !result.contains(item) { result.append(item) }
        }
    }
}
