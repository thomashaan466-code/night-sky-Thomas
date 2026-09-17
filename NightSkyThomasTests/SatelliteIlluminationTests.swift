import XCTest
@testable import NightSkyThomas

final class SatelliteIlluminationTests: XCTestCase {
    private let astronomicalUnitKilometers = 149_597_870.7

    func testSatelliteBehindEarthIsInUmbra() {
        let result = SatelliteIlluminationGeometry.classify(
            satellitePosition: earthFixed(7_000, 0, 0),
            sunPosition: earthFixed(-astronomicalUnitKilometers, 0, 0)
        )

        XCTAssertEqual(result, .umbra)
    }

    func testSatelliteBetweenEarthAndSunIsSunlit() {
        let result = SatelliteIlluminationGeometry.classify(
            satellitePosition: earthFixed(7_000, 0, 0),
            sunPosition: earthFixed(astronomicalUnitKilometers, 0, 0)
        )

        XCTAssertEqual(result, .sunlit)
    }

    func testPartialDiskOverlapIsPenumbra() {
        // At 7,000 km geocentric distance Earth's apparent angular radius is ~65.7°.
        // A Sun direction ~65.8° from the Earth-center direction therefore intersects
        // the narrow penumbral band without entering the umbra.
        let separationDegrees = 65.8
        let separation = separationDegrees * .pi / 180
        let satellite = SIMD3<Double>(7_000, 0, 0)
        let satelliteToSunDirection = SIMD3<Double>(
            -cos(separation),
            sin(separation),
            0
        )
        let sun = satellite + satelliteToSunDirection * astronomicalUnitKilometers

        XCTAssertEqual(
            SatelliteIlluminationGeometry.classify(
                satellitePosition: EarthFixedPosition(kilometers: satellite),
                sunPosition: EarthFixedPosition(kilometers: sun)
            ),
            .penumbra
        )
    }

    func testInvalidPositionInsideEarthReturnsNil() {
        XCTAssertNil(SatelliteIlluminationGeometry.classify(
            satellitePosition: earthFixed(1_000, 0, 0),
            sunPosition: earthFixed(astronomicalUnitKilometers, 0, 0)
        ))
    }

    func testVanguardReferenceStatesMatchSkyfieldAndJPLDE421() throws {
        // Independently checked with Skyfield 1.55 `is_sunlit` using JPL DE421.
        // These instants are deliberately far from an eclipse boundary so this test
        // validates the full TLE -> SGP4 TEME -> ECEF -> solar-shadow integration.
        let vanguard = TLERecord(
            name: "VANGUARD 1",
            line1: "1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753",
            line2: "2 00005  34.2682 331.5174 1849677 331.7664  19.3264 10.82419157413667"
        )
        let service = SatelliteIlluminationService()

        XCTAssertEqual(
            try service.illumination(
                tleRecord: vanguard,
                at: makeUTCDate(year: 2000, month: 6, day: 28, hour: 0, minute: 0)
            ),
            .sunlit
        )
        XCTAssertEqual(
            try service.illumination(
                tleRecord: vanguard,
                at: makeUTCDate(year: 2000, month: 6, day: 28, hour: 1, minute: 15)
            ),
            .umbra
        )
    }

    private func earthFixed(_ x: Double, _ y: Double, _ z: Double) -> EarthFixedPosition {
        EarthFixedPosition(xKilometers: x, yKilometers: y, zKilometers: z)
    }

    private func makeUTCDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }
}
