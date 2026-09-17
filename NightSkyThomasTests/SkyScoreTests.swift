import XCTest
@testable import NightSkyThomasCore

final class SkyScoreTests: XCTestCase {
    func testHighQualityNightEventGetsHighScore() {
        let event = SkyEvent(
            title: "ISS",
            type: .iss,
            startDate: Date(),
            azimuthDegrees: 250,
            elevationDegrees: 80,
            magnitude: -3.0,
            baseImportance: 1.0,
            summary: "Test",
            sourceName: "Test"
        )
        let conditions = ObservationConditions(
            cloudCover: 0,
            visibilityMeters: 30_000,
            precipitationProbability: 0,
            isDark: true
        )

        let result = SkyScore.calculate(event: event, conditions: conditions)

        XCTAssertGreaterThanOrEqual(result.score, 85)
        XCTAssertGreaterThanOrEqual(result.visibilityChance, 85)
    }

    func testDaylightReducesNightSensitiveEvent() {
        let event = SkyEvent(
            title: "Aurora",
            type: .aurora,
            startDate: Date(),
            azimuthDegrees: 0,
            elevationDegrees: 20,
            magnitude: nil,
            baseImportance: 0.8,
            summary: "Test",
            sourceName: "Test"
        )
        let daytimeConditions = ObservationConditions(
            cloudCover: 0,
            visibilityMeters: 30_000,
            precipitationProbability: 0,
            isDark: false
        )
        let nighttimeConditions = ObservationConditions(
            cloudCover: 0,
            visibilityMeters: 30_000,
            precipitationProbability: 0,
            isDark: true
        )

        let dayResult = SkyScore.calculate(event: event, conditions: daytimeConditions)
        let nightResult = SkyScore.calculate(event: event, conditions: nighttimeConditions)

        XCTAssertLessThan(dayResult.score, nightResult.score)
    }
}
