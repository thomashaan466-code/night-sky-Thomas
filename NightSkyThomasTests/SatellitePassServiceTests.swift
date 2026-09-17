import XCTest
@testable import NightSkyThomas

final class SatellitePassServiceTests: XCTestCase {
    // Vanguard 1 sample from the public Vallado/CelesTrak SGP4 verification data family.
    // These tests focus on invariants in our observer/pass layer; SwiftSGP4 owns the
    // underlying propagator verification suite.
    private let vanguard = TLERecord(
        name: "VANGUARD 1",
        line1: "1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753",
        line2: "2 00005  34.2682 331.5174 1849677 331.7664  19.3264 10.82419157413667"
    )
    private let observer = ObserverLocation(latitude: 51.50, longitude: 3.61, altitudeMeters: 5)
    private let referenceStart = ISO8601DateFormatter().date(from: "2000-06-28T00:00:00Z")!

    func testPassesAreChronologicalAndGeometricallyConsistent() throws {
        let service = SatellitePassService()
        let end = referenceStart.addingTimeInterval(48 * 60 * 60)

        let passes = try service.passes(
            tleRecord: vanguard,
            observer: observer,
            from: referenceStart,
            through: end,
            minimumElevation: 10
        )

        XCTAssertFalse(passes.isEmpty)
        for pass in passes {
            XCTAssertLessThan(pass.rise.date, pass.culmination.date)
            XCTAssertLessThan(pass.culmination.date, pass.setAngle.date)
            XCTAssertGreaterThanOrEqual(pass.rise.elevationDegrees, 9.99)
            XCTAssertGreaterThanOrEqual(pass.setAngle.elevationDegrees, 9.99)
            XCTAssertGreaterThanOrEqual(pass.culmination.elevationDegrees, pass.rise.elevationDegrees)
            XCTAssertGreaterThanOrEqual(pass.culmination.elevationDegrees, pass.setAngle.elevationDegrees)
            XCTAssertTrue((0..<360).contains(pass.rise.azimuthDegrees))
            XCTAssertTrue((0..<360).contains(pass.culmination.azimuthDegrees))
            XCTAssertTrue((0..<360).contains(pass.setAngle.azimuthDegrees))
            XCTAssertGreaterThan(pass.duration, 0)
        }
    }

    func testWindowStartingMidPassDoesNotFabricateRiseAtWindowStart() throws {
        let service = SatellitePassService()
        let fullWindow = try service.passes(
            tleRecord: vanguard,
            observer: observer,
            from: referenceStart,
            through: referenceStart.addingTimeInterval(48 * 60 * 60),
            minimumElevation: 10
        )
        let first = try XCTUnwrap(fullWindow.first)
        let midPass = first.rise.date.addingTimeInterval(first.duration / 2)

        let clipped = try service.passes(
            tleRecord: vanguard,
            observer: observer,
            from: midPass,
            through: first.setAngle.date.addingTimeInterval(60),
            minimumElevation: 10
        )

        XCTAssertTrue(clipped.isEmpty)
    }

    func testWindowEndingMidPassDoesNotReturnIncompletePass() throws {
        let service = SatellitePassService()
        let fullWindow = try service.passes(
            tleRecord: vanguard,
            observer: observer,
            from: referenceStart,
            through: referenceStart.addingTimeInterval(48 * 60 * 60),
            minimumElevation: 10
        )
        let first = try XCTUnwrap(fullWindow.first)
        let midPass = first.rise.date.addingTimeInterval(first.duration / 2)

        let clipped = try service.passes(
            tleRecord: vanguard,
            observer: observer,
            from: first.rise.date.addingTimeInterval(-60),
            through: midPass,
            minimumElevation: 10
        )

        XCTAssertTrue(clipped.isEmpty)
    }

    func testEmptyWindowReturnsNoPasses() throws {
        let service = SatellitePassService()
        let date = Date(timeIntervalSince1970: 0)

        XCTAssertTrue(try service.passes(
            tleRecord: vanguard,
            observer: observer,
            from: date,
            through: date,
            minimumElevation: 10
        ).isEmpty)
    }

    func testMalformedShortTLEDoesNotCrash() {
        let service = SatellitePassService()
        let malformed = TLERecord(name: "BAD", line1: "1 BAD", line2: "2 BAD")
        let start = Date(timeIntervalSince1970: 0)

        XCTAssertThrowsError(try service.passes(
            tleRecord: malformed,
            observer: observer,
            from: start,
            through: start.addingTimeInterval(3600),
            minimumElevation: 10
        ))
    }
}
