import Foundation

struct ForecastConditions: Hashable, Sendable {
    let date: Date
    let conditions: ObservationConditions
}

protocol ForecastWeatherProviding: Sendable {
    func forecast(latitude: Double, longitude: Double) async throws -> [ForecastConditions]
    func conditions(near date: Date, latitude: Double, longitude: Double) async throws -> ObservationConditions
}

enum ForecastWeatherError: Error, Equatable {
    case requestedDateUnavailable
}

struct OpenMeteoForecastWeatherService: ForecastWeatherProviding, Sendable {
    private static let maximumHourlyMatchDistance: TimeInterval = 60 * 60

    private struct Response: Decodable {
        let hourly: Hourly

        struct Hourly: Decodable {
            let time: [String]
            let cloudCover: [Double]
            let precipitationProbability: [Double]
            let visibility: [Double]
            let isDay: [Int]

            enum CodingKeys: String, CodingKey {
                case time
                case cloudCover = "cloud_cover"
                case precipitationProbability = "precipitation_probability"
                case visibility
                case isDay = "is_day"
            }
        }
    }

    func forecast(latitude: Double, longitude: Double) async throws -> [ForecastConditions] {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "hourly", value: "cloud_cover,precipitation_probability,visibility,is_day"),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(name: "timezone", value: "GMT")
        ]

        guard let url = components.url else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        let count = [
            decoded.hourly.time.count,
            decoded.hourly.cloudCover.count,
            decoded.hourly.precipitationProbability.count,
            decoded.hourly.visibility.count,
            decoded.hourly.isDay.count
        ].min() ?? 0

        return (0..<count).compactMap { index in
            guard let date = formatter.date(from: decoded.hourly.time[index]) else { return nil }
            return ForecastConditions(
                date: date,
                conditions: ObservationConditions(
                    cloudCover: decoded.hourly.cloudCover[index],
                    visibilityMeters: decoded.hourly.visibility[index],
                    precipitationProbability: decoded.hourly.precipitationProbability[index],
                    isDark: decoded.hourly.isDay[index] == 0
                )
            )
        }
    }

    func conditions(near date: Date, latitude: Double, longitude: Double) async throws -> ObservationConditions {
        let values = try await forecast(latitude: latitude, longitude: longitude)
        return try Self.conditions(near: date, from: values)
    }

    static func conditions(
        near date: Date,
        from values: [ForecastConditions]
    ) throws -> ObservationConditions {
        guard let firstDate = values.map(\.date).min(),
              let lastDate = values.map(\.date).max(),
              (firstDate...lastDate).contains(date),
              let closest = values.min(by: {
                  abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
              }),
              abs(closest.date.timeIntervalSince(date)) <= maximumHourlyMatchDistance else {
            throw ForecastWeatherError.requestedDateUnavailable
        }
        return closest.conditions
    }
}
