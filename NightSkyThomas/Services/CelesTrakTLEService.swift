import Foundation

struct TLERecord: Hashable, Sendable {
    let name: String
    let line1: String
    let line2: String
}

protocol TLEProviding {
    func tle(catalogNumber: Int) async throws -> TLERecord
}

actor CelesTrakTLEService: TLEProviding {
    private struct CacheEntry {
        let tle: TLERecord
        let fetchedAt: Date
    }

    private var cache: [Int: CacheEntry] = [:]
    private let cacheLifetime: TimeInterval = 2 * 60 * 60

    func tle(catalogNumber: Int) async throws -> TLERecord {
        if let cached = cache[catalogNumber], Date().timeIntervalSince(cached.fetchedAt) < cacheLifetime {
            return cached.tle
        }

        var components = URLComponents(string: "https://celestrak.org/NORAD/elements/gp.php")!
        components.queryItems = [
            URLQueryItem(name: "CATNR", value: String(catalogNumber)),
            URLQueryItem(name: "FORMAT", value: "TLE")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }

        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let i = lines.firstIndex(where: { $0.hasPrefix("1 ") }),
              i + 1 < lines.count,
              lines[i + 1].hasPrefix("2 ") else {
            throw URLError(.cannotParseResponse)
        }

        let name = i > 0 ? lines[i - 1] : "NORAD \(catalogNumber)"
        let result = TLERecord(name: name, line1: lines[i], line2: lines[i + 1])
        cache[catalogNumber] = CacheEntry(tle: result, fetchedAt: Date())
        return result
    }
}
