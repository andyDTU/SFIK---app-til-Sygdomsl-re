import SwiftUI
import PDFKit

struct PDFViewer: View {
    let filename: String

    var body: some View {
        PDFKitRepresentedView(filename: filename)
            .navigationTitle(filename.replacingOccurrences(of: ".pdf", with: ""))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
    }
}

#if os(iOS)
struct PDFKitRepresentedView: UIViewRepresentable {
    let filename: String

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".pdf", with: ""), withExtension: "pdf") {
            if let document = PDFDocument(url: url) {
                pdfView.document = document
            }
        }
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
#else
struct PDFKitRepresentedView: NSViewRepresentable {
    let filename: String

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".pdf", with: ""), withExtension: "pdf") {
            if let document = PDFDocument(url: url) {
                pdfView.document = document
            }
        }
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {}
}
#endif
