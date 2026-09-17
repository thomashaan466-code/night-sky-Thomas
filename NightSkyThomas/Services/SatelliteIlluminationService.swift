import Foundation
import SwiftSGP4

protocol SatelliteIlluminationProviding: Sendable {
    func illumination(tleRecord: TLERecord, at date: Date) throws -> SatelliteIllumination
}

enum SatelliteIlluminationError: Error, Equatable {
    case invalidGeometry
}

/// Couples SwiftSGP4 propagation to the shadow geometry without mixing reference frames.
///
/// SwiftSGP4 returns TEME kilometers. Its date-aware converter rotates that state to
/// ECEF/PEF, matching `AstronomyMath.solarPositionEarthFixed`. This follows Vallado's
/// recommended TEME -> PEF path for General Perturbations data. UTC is used as the
/// practical UT1 approximation, consistent with SwiftSGP4's converter and the expected
/// accuracy of TLE/SGP4 predictions.
struct SatelliteIlluminationService: SatelliteIlluminationProviding, Sendable {
    func illumination(tleRecord: TLERecord, at date: Date) throws -> SatelliteIllumination {
        let tle = try TLE(
            name: tleRecord.name,
            lineOne: tleRecord.line1,
            lineTwo: tleRecord.line2
        )
        let propagator = try PropagatorFactory.create(tle: tle)
        let state = try propagator.propagate(
            minutesSinceEpoch: date.timeIntervalSince(tle.epoch) / 60
        )
        let (positionECEF, _) = CoordinateConverter.temeToECEF(
            position: state.position,
            velocity: state.velocity,
            date: date
        )
        let satellitePosition = EarthFixedPosition(
            xKilometers: positionECEF.x,
            yKilometers: positionECEF.y,
            zKilometers: positionECEF.z
        )

        guard let result = SatelliteIlluminationGeometry.classify(
            satellitePosition: satellitePosition,
            sunPosition: AstronomyMath.solarPositionEarthFixed(date: date)
        ) else {
            throw SatelliteIlluminationError.invalidGeometry
        }
        return result
    }
}
