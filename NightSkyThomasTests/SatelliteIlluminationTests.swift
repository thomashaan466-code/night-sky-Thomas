import XCTest
@testable import NightSkyThomas

final class SatelliteIlluminationTests: XCTestCase {
    private let astronomicalUnitKilometers = 149_597_870.7

    func testSatelliteBehindEarthIsInUmbra() {
        let result = SatelliteIlluminationGeometry.classify(
            satellitePosition: SIMD3(7_000, 0, 0),
            sunPosition: SIMD3(-astronomicalUnitKilometers, 0, 0)
        )

        XCTAssertEqual(result, .umbra)
    }

    func testSatelliteBetweenEarthAndSunIsSunlit() {
        let result = SatelliteIlluminationGeometry.classify(
            satellitePosition: SIMD3(7_000, 0, 0),
            sunPosition: SIMD3(astronomicalUnitKilometers, 0, 0)
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
                satellitePosition: satellite,
                sunPosition: sun
            ),
            .penumbra
        )
    }

    func testInvalidPositionInsideEarthReturnsNil() {
        XCTAssertNil(SatelliteIlluminationGeometry.classify(
            satellitePosition: SIMD3(1_000, 0, 0),
            sunPosition: SIMD3(astronomicalUnitKilometers, 0, 0)
        ))
    }
}
