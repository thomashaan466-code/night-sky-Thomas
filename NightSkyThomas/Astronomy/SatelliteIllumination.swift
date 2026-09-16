import Foundation

enum SatelliteIllumination: String, Hashable, Sendable {
    case sunlit
    case penumbra
    case umbra
}

enum SatelliteIlluminationGeometry {
    // Mean radii are sufficient for the angular-disk eclipse model used here.
    static let earthRadiusKilometers = 6_378.137
    static let sunRadiusKilometers = 695_700.0

    /// Classifies the apparent overlap of Earth and Sun as seen from a satellite.
    ///
    /// All vectors must use the same Earth-centered inertial frame and kilometer units:
    /// `satellitePosition` is Earth -> satellite and `sunPosition` is Earth -> Sun.
    /// This function intentionally performs only shadow geometry. Observer darkness,
    /// elevation, brightness and weather belong to the visibility layer.
    static func classify(
        satellitePosition: SIMD3<Double>,
        sunPosition: SIMD3<Double>
    ) -> SatelliteIllumination? {
        let satelliteToEarth = -satellitePosition
        let satelliteToSun = sunPosition - satellitePosition

        let earthDistance = length(satelliteToEarth)
        let sunDistance = length(satelliteToSun)
        guard earthDistance.isFinite,
              sunDistance.isFinite,
              earthDistance > earthRadiusKilometers,
              sunDistance > sunRadiusKilometers else {
            return nil
        }

        let earthAngularRadius = asin(clamp(earthRadiusKilometers / earthDistance))
        let sunAngularRadius = asin(clamp(sunRadiusKilometers / sunDistance))
        let centerSeparation = angle(between: satelliteToEarth, and: satelliteToSun)

        guard earthAngularRadius.isFinite,
              sunAngularRadius.isFinite,
              centerSeparation.isFinite else {
            return nil
        }

        if earthAngularRadius > sunAngularRadius,
           centerSeparation < earthAngularRadius - sunAngularRadius {
            return .umbra
        }

        if centerSeparation < earthAngularRadius + sunAngularRadius {
            return .penumbra
        }

        return .sunlit
    }

    private static func length(_ vector: SIMD3<Double>) -> Double {
        sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    }

    private static func angle(between lhs: SIMD3<Double>, and rhs: SIMD3<Double>) -> Double {
        let lhsLength = length(lhs)
        let rhsLength = length(rhs)
        guard lhsLength > 0, rhsLength > 0 else { return .nan }
        let dot = lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
        return acos(clamp(dot / (lhsLength * rhsLength)))
    }

    private static func clamp(_ value: Double) -> Double {
        min(1, max(-1, value))
    }
}
