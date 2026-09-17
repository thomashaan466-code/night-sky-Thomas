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
        XCTAssertEqual(AstronomyMath.twilightState(solarAltitudeDegrees: -6), .civil)
        XCTAssertEqual(AstronomyMath.twilightState(solarAltitudeDegrees: -6.0001), .nautical)
        XCTAssertEqual(AstronomyMath.twilightState(solarAltitudeDegrees: -12), .nautical)
        XCTAssertEqual(AstronomyMath.twilightState(solarAltitudeDegrees: -12.0001), .astronomical)
        XCTAssertEqual(AstronomyMath.twilightState(solarAltitudeDegrees: -18), .astronomical)
        XCTAssertEqual(AstronomyMath.twilightState(solarAltitudeDegrees: -18.0001), .night)
    }

    func testEarthFixedSunDirectionMatchesJPLHorizonsReference() {
        let date = makeUTCDate(year: 2000, month: 6, day: 28, hour: 0)
        let calculated = AstronomyMath.solarPositionEarthFixed(date: date).kilometers

        // JPL Horizons DE441/ICRF geocentric Sun vector for 2000-06-28 00:00 TDB,
        // rotated to Earth-fixed with the Vallado GMST expression. TDB-vs-UTC and
        // ICRF-vs-TEME differences are negligible at this intentionally loose bound.
        let jplReferenceECEF = SIMD3<Double>(
            -139_695_864.30145976,
            -1_944_662.293820262,
            60_093_559.65973263
        )

        XCTAssertLessThan(
            angularSeparationDegrees(calculated, jplReferenceECEF),
            0.2
        )
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

    private func angularSeparationDegrees(_ lhs: SIMD3<Double>, _ rhs: SIMD3<Double>) -> Double {
        let lhsLength = sqrt(lhs.x * lhs.x + lhs.y * lhs.y + lhs.z * lhs.z)
        let rhsLength = sqrt(rhs.x * rhs.x + rhs.y * rhs.y + rhs.z * rhs.z)
        let cosine = (lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z) / (lhsLength * rhsLength)
        return acos(min(1, max(-1, cosine))) * 180 / .pi
    }
}
