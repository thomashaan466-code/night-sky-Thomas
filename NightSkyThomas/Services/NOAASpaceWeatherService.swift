import Foundation

struct SpaceWeatherSnapshot: Hashable {
    let kp: Double?
    let measuredAt: Date?

    var activityLabel: String {
        guard let kp else { return "Onbekend" }
        switch kp {
        case 7...: return "Zeer sterk"
        case 6..<7: return "Sterk"
        case 5..<6: return "Stormniveau"
        case 4..<5: return "Actief"
        default: return "Rustig"
        }
    }
}

actor NOAASpaceWeatherService {
    private struct KpRow: Decodable {
        let timeTag: String
        let kp: Double

        enum CodingKeys: String, CodingKey {
            case timeTag = "time_tag"
            case kp
        }
    }

    func currentSnapshot() async throws -> SpaceWeatherSnapshot {
        let url = URL(string: "https://services.swpc.noaa.gov/json/planetary_k_index_1m.json")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let rows = try JSONDecoder().decode([KpRow].self, from: data)
        guard let latest = rows.last else { return SpaceWeatherSnapshot(kp: nil, measuredAt: nil) }

        let formatter = ISO8601DateFormatter()
        return SpaceWeatherSnapshot(kp: latest.kp, measuredAt: formatter.date(from: latest.timeTag))
    }
}
