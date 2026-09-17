import Foundation

struct SpaceWeatherSnapshot: Hashable, Sendable {
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
        let estimatedKp: Double

        enum CodingKeys: String, CodingKey {
            case timeTag = "time_tag"
            case estimatedKp = "estimated_kp"
        }
    }

    func currentSnapshot() async throws -> SpaceWeatherSnapshot {
        let url = URL(string: "https://services.swpc.noaa.gov/json/planetary_k_index_1m.json")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try Self.decodeSnapshot(from: data)
    }

    static func decodeSnapshot(from data: Data) throws -> SpaceWeatherSnapshot {
        let rows = try JSONDecoder().decode([KpRow].self, from: data)
        guard !rows.isEmpty else {
            return SpaceWeatherSnapshot(kp: nil, measuredAt: nil)
        }

        let datedRows = rows.compactMap { row -> (row: KpRow, date: Date)? in
            guard let date = parseSWPCTimestamp(row.timeTag) else { return nil }
            return (row, date)
        }
        guard let latest = datedRows.max(by: { $0.date < $1.date }) else {
            throw URLError(.cannotParseResponse)
        }

        return SpaceWeatherSnapshot(kp: latest.row.estimatedKp, measuredAt: latest.date)
    }

    private static func parseSWPCTimestamp(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
}
