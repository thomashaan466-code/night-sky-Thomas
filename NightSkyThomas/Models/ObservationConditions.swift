import Foundation

struct ObservationConditions: Hashable, Codable {
    let cloudCover: Double
    let visibilityMeters: Double?
    let precipitationProbability: Double
    let isDark: Bool

    static let ideal = ObservationConditions(
        cloudCover: 0,
        visibilityMeters: 30_000,
        precipitationProbability: 0,
        isDark: true
    )
}
