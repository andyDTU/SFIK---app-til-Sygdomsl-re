import SwiftUI

struct ReadingMaterialView: View {
    let kapitler = [
        "Allergiske sygdomme.pdf", "Bevægeapparatets sygdomme.pdf", "Blodsygdomme.pdf", "Danskernes sundhedstilstand og Patientens vej gennem sundhedsvæsnet.pdf",
        "Diagnostiske modaliteter.pdf", "Gynækologiske sygdomme og obstetrik.pdf", "Hjerte-kar-sygdomme.pdf", "Kræftsygdomme.pdf",
        "Mave-Tarm-sygdomme.pdf", "Neurologiske sygdomme.pdf", "Nyre- og urinvejssygdomme.pdf", "Ordliste og Stikordsregister.pdf",
        "Psykiske sygdomme.pdf", "Sygdomslære_for_ikke_klinikere-kopi-1-1.pdf", "endokrine sygdomme.pdf", "infektionssygdomme.pdf", "lungesygdomme.pdf"
    ]

    let forelaesninger = [
        "2025 MS, demens og PD-1.pdf", "2026 Apopleksi KRJ.pdf", "2026 Epilepsi KRJ.pdf", "210322  Sygdomslære  Hjerte_tbs_FINAL.pdf",
        "Allergiske sygdomme - Claus Desler (opdateret - 2025).pdf", "Anæmier.pdf", "Bevægeapparatets sygdomme_F2.pdf",
        "Bevægeapparatets sygdomme_F3.pdf", "Bevægeapparatets sygdomme_F4.pdf", "Blodsygdomme_anæmier.pdf", "Blodsygdomme_leukæmi.pdf",
        "Forelæsning_sygdomslære_2024_CM.pdf", "Infektionssygdomme_210426.pdf", "Lever, pankreas og galde sygdomme.pdf", "Lunge-sygdomme 2026.pdf",
        "Mikrobiologi Kompendium - SFIK.pdf", "Mikrobiologi forelæsning 1_TTN.pdf", "Mikrobiologi forelæsning 2_TTN.pdf",
        "Psykiatri Forår 2026 Lektion 10.pdf", "Psykiatri forår 2026 lektion 5+6.pdf", "Psykiatri forår 2026 lektion 7+8.pdf",
        "Psykiatri forår 2026 lektion 9 .pdf", "SLIDES adipositas mm til studerende-1.pdf", "Sygdomslære for ikke-klinikere -AHE,KE maj 2025.pdf",
        "Thyroidea-sygdomme + osteoporose.pdf", "Ulcus, Inflammatoriske tarmsygdomme, malabsorption, appendicitis og Diarré.pdf"
    ]

    let sauSlides = [
        "Allergiske sygdomme PP opdateret F26 pptx.pdf", "Bevægeapparatets sygdomme PP opdateret F26.pdf", "Endokrine sygdomme opdateret F26.pdf",
        "Gyn-obs-sygdomme opdateret F26.pdf", "Hjerte-kar sygdomme PP opdateret F26.pdf", "Infektionssygdomme PP opdateret F26.pdf",
        "Kræftsygdomme PP opdateret F26.pdf", "Lungesygdomme PP opdateret F26.pdf", "Mave-tarm-sygdomme PP opdateret F26.pdf",
        "Neurologiske sygdomme PP opdateret F26.pdf", "Nyre-urinvejssygdomme PP opdateret F26.pdf", "Psykiske sygdomme opdateret F26.pdf",
        "Urinvejsinfektion.pdf"
    ]

    var body: some View {
        #if os(macOS)
        readingContent
        #else
        NavigationView {
            readingContent
        }
        #endif
    }

    private var readingContent: some View {
        List {
            Section(header: Text("Kapitler")) {
                ForEach(kapitler, id: \.self) { file in
                    PDFLink(filename: file)
                }
            }

            Section(header: Text("Forelæsningsslides")) {
                ForEach(forelaesninger, id: \.self) { file in
                    PDFLink(filename: file)
                }
            }

            Section(header: Text("SAU Slides")) {
                ForEach(sauSlides, id: \.self) { file in
                    PDFLink(filename: file)
                }
            }
        }
        .navigationTitle("Pensum")
        #if os(iOS)
        .listStyle(InsetGroupedListStyle())
        #else
        .listStyle(.inset)
        #endif
    }
}

struct PDFLink: View {
    let filename: String
    var displayName: String {
        filename.replacingOccurrences(of: ".pdf", with: "")
    }

    var body: some View {
        NavigationLink(destination: PDFViewer(filename: filename)) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.red)
                Text(displayName)
                    .lineLimit(1)
            }
        }
    }
}
