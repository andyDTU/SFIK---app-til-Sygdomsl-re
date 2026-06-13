import Foundation
import Combine
import SwiftUI

class DataLoader: ObservableObject {
    @Published var diseases: [Disease] = []
    
    init() {
        loadData()
    }
    
    func loadData() {
        guard let url = Bundle.main.url(forResource: "diseases", withExtension: "json") else {
            print("Kunne ikke finde diseases.json i app bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Disease].self, from: data)
            DispatchQueue.main.async {
                self.diseases = decoded
            }
        } catch {
            print("Fejl ved afkodning af diseases.json: \(error)")
        }
    }
}
