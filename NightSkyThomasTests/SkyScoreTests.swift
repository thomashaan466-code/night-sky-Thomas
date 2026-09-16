import XCTest
@testable import NightSkyThomas

final class SkyScoreTests: XCTestCase {
    func testClearDarkHighBrightPassScoresHigherThanCloudyPass() {
        let event = SkyEvent(
            title: "ISS",
            type: .iss,
            startDate: Date(),
            elevationDegrees: 80,
            magnitude: -3.5,
            baseImportance: 0.98,
            summary: "Test",
            sourceName: "Test"
        )

        let clear = ObservationConditions(
            cloudCover: 5,
            visibilityMeters: 30_000,
            precipitationProbability: 0,
            isDark: true
        )
        let cloudy = ObservationConditions(
            cloudCover: 95,
            visibilityMeters: 3_000,
            precipitationProbability: 80,
            isDark: true
        )

        XCTAssertGreaterThan(
            SkyScore.calculate(event: event, conditions: clear).score,
            SkyScore.calculate(event: event, conditions: cloudy).score
        )
    }

    func testScoreAlwaysStaysWithinBounds() {
        let event = SkyEvent(
            title: "Boundary",
            type: .meteor,
            startDate: Date(),
            elevationDegrees: 120,
            magnitude: -10,
            baseImportance: 4,
            summary: "Test",
            sourceName: "Test"
        )

        let result = SkyScore.calculate(event: event, conditions: .ideal)
        XCTAssertTrue((0...100).contains(result.score))
        XCTAssertTrue((0...100).contains(result.visibilityChance))
    }
}
