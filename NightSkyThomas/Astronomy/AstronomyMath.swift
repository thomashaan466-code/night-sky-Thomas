import Foundation

struct HorizontalCoordinate: Hashable {
    let azimuth: Double
    let altitude: Double
}

enum AstronomyMath {
    static func julianDate(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86_400 + 2_440_587.5
    }

    static func localSiderealTime(date: Date, longitudeDegrees: Double) -> Double {
        let jd = julianDate(date)
        let d = jd - 2_451_545.0
        let gmst = 280.46061837 + 360.98564736629 * d
        return normalizeDegrees(gmst + longitudeDegrees)
    }

    static func horizontalCoordinate(
        rightAscensionDegrees: Double,
        declinationDegrees: Double,
        date: Date,
        latitudeDegrees: Double,
        longitudeDegrees: Double
    ) -> HorizontalCoordinate {
        let lst = localSiderealTime(date: date, longitudeDegrees: longitudeDegrees)
        let hourAngle = degreesToRadians(normalizeSignedDegrees(lst - rightAscensionDegrees))
        let dec = degreesToRadians(declinationDegrees)
        let lat = degreesToRadians(latitudeDegrees)

        let sinAlt = sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(hourAngle)
        let altitude = asin(sinAlt)

        let y = -sin(hourAngle) * cos(dec)
        let x = sin(dec) * cos(lat) - cos(dec) * sin(lat) * cos(hourAngle)
        let azimuth = atan2(y, x)

        return HorizontalCoordinate(
            azimuth: normalizeDegrees(radiansToDegrees(azimuth)),
            altitude: radiansToDegrees(altitude)
        )
    }

    static func angularDifference(from heading: Double, to targetAzimuth: Double) -> Double {
        normalizeSignedDegrees(targetAzimuth - heading)
    }

    private static func normalizeDegrees(_ value: Double) -> Double {
        let result = value.truncatingRemainder(dividingBy: 360)
        return result < 0 ? result + 360 : result
    }

    private static func normalizeSignedDegrees(_ value: Double) -> Double {
        var value = normalizeDegrees(value)
        if value > 180 { value -= 360 }
        return value
    }

    private static func degreesToRadians(_ degrees: Double) -> Double { degrees * .pi / 180 }
    private static func radiansToDegrees(_ radians: Double) -> Double { radians * 180 / .pi }
}
