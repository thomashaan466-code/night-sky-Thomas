import Foundation

protocol WeatherProviding {
    func conditions(latitude: Double, longitude: Double) async throws -> ObservationConditions
}

struct OpenMeteoWeatherService: WeatherProviding {
    private struct Response: Decodable {
        let current: Current

        struct Current: Decodable {
            let cloudCover: Double
            let precipitation: Double
            let visibility: Double?
            let isDay: Int

            enum CodingKeys: String, CodingKey {
                case cloudCover = "cloud_cover"
                case precipitation
                case visibility
                case isDay = "is_day"
            }
        }
    }

    func conditions(latitude: Double, longitude: Double) async throws -> ObservationConditions {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "cloud_cover,precipitation,visibility,is_day"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components.url else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return ObservationConditions(
            cloudCover: decoded.current.cloudCover,
            visibilityMeters: decoded.current.visibility,
            precipitationProbability: decoded.current.precipitation > 0 ? 100 : 0,
            isDark: decoded.current.isDay == 0
        )
    }
}
