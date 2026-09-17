import XCTest
@testable import NightSkyThomas

final class ForecastWeatherServiceTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testSelectsNearestHourlyConditionsInsideForecastWindow() throws {
        let expected = ObservationConditions(
            cloudCover: 25,
            visibilityMeters: 20_000,
            precipitationProbability: 10,
            isDark: true
        )
        let values = [
            forecast(hourOffset: 0, conditions: .ideal),
            forecast(hourOffset: 1, conditions: expected),
            forecast(hourOffset: 2, conditions: .ideal)
        ]

        XCTAssertEqual(
            try OpenMeteoForecastWeatherService.conditions(
                near: start.addingTimeInterval(50 * 60),
                from: values
            ),
            expected
        )
    }

    func testRejectsDateBeforeForecastWindow() {
        let values = [
            forecast(hourOffset: 0, conditions: .ideal),
            forecast(hourOffset: 1, conditions: .ideal)
        ]

        XCTAssertThrowsError(try OpenMeteoForecastWeatherService.conditions(
            near: start.addingTimeInterval(-1),
            from: values
        )) { error in
            XCTAssertEqual(error as? ForecastWeatherError, .requestedDateUnavailable)
        }
    }

    func testRejectsDateAfterForecastWindow() {
        let values = [
            forecast(hourOffset: 0, conditions: .ideal),
            forecast(hourOffset: 1, conditions: .ideal)
        ]

        XCTAssertThrowsError(try OpenMeteoForecastWeatherService.conditions(
            near: start.addingTimeInterval(60 * 60 + 1),
            from: values
        )) { error in
            XCTAssertEqual(error as? ForecastWeatherError, .requestedDateUnavailable)
        }
    }

    func testRejectsLargeGapInsideNominalForecastWindow() {
        let values = [
            forecast(hourOffset: 0, conditions: .ideal),
            forecast(hourOffset: 4, conditions: .ideal)
        ]

        XCTAssertThrowsError(try OpenMeteoForecastWeatherService.conditions(
            near: start.addingTimeInterval(2 * 60 * 60),
            from: values
        )) { error in
            XCTAssertEqual(error as? ForecastWeatherError, .requestedDateUnavailable)
        }
    }

    private func forecast(
        hourOffset: Double,
        conditions: ObservationConditions
    ) -> ForecastConditions {
        ForecastConditions(
            date: start.addingTimeInterval(hourOffset * 60 * 60),
            conditions: conditions
        )
    }
}
