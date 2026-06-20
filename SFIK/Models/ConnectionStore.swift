import Foundation

struct DiseaseConnection: Identifiable, Codable {
    let id: String
    let diseaseA: String
    let diseaseB: String
    let type: String
    let bridge: String

    func otherID(from diseaseID: String) -> String {
        diseaseID == diseaseA ? diseaseB : diseaseA
    }
}

final class ConnectionStore {
    static let shared = ConnectionStore()

    let all: [DiseaseConnection]

    private init() {
        guard let url = Bundle.main.url(forResource: "connections", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { all = []; return }
        struct Root: Codable { let connections: [DiseaseConnection] }
        all = (try? JSONDecoder().decode(Root.self, from: data))?.connections ?? []
    }

    func connections(for id: String) -> [DiseaseConnection] {
        all.filter { $0.diseaseA == id || $0.diseaseB == id }
    }
}
