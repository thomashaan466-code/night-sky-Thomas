import XCTest
@testable import NightSkyThomas

final class AstronomyMathTests: XCTestCase {
    func testSolarPositionAtGreenwichEquinoxNoonIsNearZenith() {
        let date = makeUTCDate(year: 2026, month: 3, day: 20, hour: 12)
        let sun = AstronomyMath.solarHorizontalCoordinate(
            date: date,
            latitudeDegrees: 0,
            longitudeDegrees: 0
        )

        XCTAssertGreaterThan(sun.altitude, 87)
        XCTAssertLessThanOrEqual(sun.altitude, 90)
        XCTAssertTrue((0..<360).contains(sun.azimuth))
    }

    func testSolarPositionAtGreenwichEquinoxMidnightIsBelowHorizon() {
        let date = makeUTCDate(year: 2026, month: 3, day: 20, hour: 0)
        let sun = AstronomyMath.solarHorizontalCoordinate(
            date: date,
            latitudeDegrees: 0,
            longitudeDegrees: 0
        )

        XCTAssertLessThan(sun.altitude, -87)
    }

    func testTwilightBoundaries() {
        XCTAssertEqual(AstronomyMath.twilightState(solarAltitudeDegrees: 10), .daylight)
        XCTAssertEqual(AstronomyMath.twilightState(solarAltitudeDegrees: -0.1), .civil)
        XCTAssertEqual(AstronomyMath.twilightState(solarAltitudeDegrees: -6), .nautical)
        XCTAssertEqual(AstronomyMath.twilightState(solarAltitudeDegrees: -12), .astronomical)
        XCTAssertEqual(AstronomyMath.twilightState(solarAltitudeDegrees: -18), .night)
    }

    private func makeUTCDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour
        ))!
    }
}
