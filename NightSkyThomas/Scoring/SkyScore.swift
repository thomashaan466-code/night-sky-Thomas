import Foundation

struct SkyScoreResult: Hashable {
    let score: Int
    let visibilityChance: Int
    let label: String
}

enum SkyScore {
    static func calculate(event: SkyEvent, conditions: ObservationConditions) -> SkyScoreResult {
        let importance = clamp(event.baseImportance, 0...1)
        let cloudFactor = 1 - clamp(conditions.cloudCover / 100, 0...1)
        let rainFactor = 1 - clamp(conditions.precipitationProbability / 100, 0...1)
        let darknessFactor = conditions.isDark ? 1.0 : daylightTolerance(for: event.type)
        let elevationFactor = event.elevationDegrees.map { clamp($0 / 70, 0.25...1) } ?? 0.75
        let brightnessFactor = brightnessScore(magnitude: event.magnitude)

        let visibility = cloudFactor * 0.58 + rainFactor * 0.12 + darknessFactor * 0.20 + elevationFactor * 0.10
        let quality = importance * 0.45 + visibility * 0.35 + brightnessFactor * 0.20

        let score = Int((clamp(quality, 0...1) * 100).rounded())
        let visibilityChance = Int((clamp(visibility, 0...1) * 100).rounded())

        return SkyScoreResult(
            score: score,
            visibilityChance: visibilityChance,
            label: label(for: score)
        )
    }

    private static func brightnessScore(magnitude: Double?) -> Double {
        guard let magnitude else { return 0.65 }
        if magnitude <= -4 { return 1 }
        if magnitude <= -2 { return 0.9 }
        if magnitude <= 0 { return 0.78 }
        if magnitude <= 2 { return 0.62 }
        if magnitude <= 4 { return 0.42 }
        return 0.25
    }

    private static func daylightTolerance(for type: SkyEventType) -> Double {
        switch type {
        case .moon, .eclipse, .rocket: return 0.7
        default: return 0.15
        }
    }

    private static func label(for score: Int) -> String {
        switch score {
        case 90...: return "Uitzonderlijk"
        case 80..<90: return "Zeer goed"
        case 65..<80: return "Goed"
        case 45..<65: return "Redelijk"
        default: return "Niet de moeite"
        }
    }

    private static func clamp(_ value: Double, _ range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
