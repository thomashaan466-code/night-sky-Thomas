import Foundation

struct SatelliteGP: Decodable, Hashable {
    let objectName: String
    let noradCatalogID: Int
    let epoch: String
    let meanMotion: Double
    let eccentricity: Double
    let inclination: Double
    let raOfAscNode: Double
    let argOfPericenter: Double
    let meanAnomaly: Double

    enum CodingKeys: String, CodingKey {
        case objectName = "OBJECT_NAME"
        case noradCatalogID = "NORAD_CAT_ID"
        case epoch = "EPOCH"
        case meanMotion = "MEAN_MOTION"
        case eccentricity = "ECCENTRICITY"
        case inclination = "INCLINATION"
        case raOfAscNode = "RA_OF_ASC_NODE"
        case argOfPericenter = "ARG_OF_PERICENTER"
        case meanAnomaly = "MEAN_ANOMALY"
    }
}

protocol SatelliteDataProviding {
    func generalPerturbations(catalogNumber: Int) async throws -> SatelliteGP
}

actor CelesTrakService: SatelliteDataProviding {
    private struct CacheEntry {
        let value: SatelliteGP
        let fetchedAt: Date
    }

    private var cache: [Int: CacheEntry] = [:]
    private let cacheLifetime: TimeInterval = 2 * 60 * 60

    func generalPerturbations(catalogNumber: Int) async throws -> SatelliteGP {
        if let cached = cache[catalogNumber], Date().timeIntervalSince(cached.fetchedAt) < cacheLifetime {
            return cached.value
        }

        var components = URLComponents(string: "https://celestrak.org/NORAD/elements/gp.php")!
        components.queryItems = [
            URLQueryItem(name: "CATNR", value: String(catalogNumber)),
            URLQueryItem(name: "FORMAT", value: "JSON")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let records = try JSONDecoder().decode([SatelliteGP].self, from: data)
        guard let first = records.first else { throw URLError(.cannotParseResponse) }
        cache[catalogNumber] = CacheEntry(value: first, fetchedAt: Date())
        return first
    }
}
