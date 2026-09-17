import Foundation

struct HorizontalCoordinate: Hashable, Sendable {
    let azimuth: Double
    let altitude: Double
}

enum TwilightState: String, Hashable, Sendable {
    case daylight
    case civil
    case nautical
    case astronomical
    case night
}

enum AstronomyMath {
    static let astronomicalUnitKilometers = 149_597_870.7

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
        let altitude = asin(clamp(sinAlt, minimum: -1, maximum: 1))

        let y = -sin(hourAngle) * cos(dec)
        let x = sin(dec) * cos(lat) - cos(dec) * sin(lat) * cos(hourAngle)
        let azimuth = atan2(y, x)

        return HorizontalCoordinate(
            azimuth: normalizeDegrees(radiansToDegrees(azimuth)),
            altitude: radiansToDegrees(altitude)
        )
    }

    /// Approximate geometric solar position using NOAA's published fractional-year equations.
    /// Inputs are an absolute Date plus east-positive longitude, so the calculation is timezone independent.
    static func solarHorizontalCoordinate(
        date: Date,
        latitudeDegrees: Double,
        longitudeDegrees: Double
    ) -> HorizontalCoordinate {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let parameters = approximateSolarParameters(date: date, calendar: calendar)

        // UTC is timezone zero in NOAA's true-solar-time equation.
        let trueSolarMinutes = parameters.fractionalHour * 60
            + parameters.equationOfTimeMinutes
            + 4 * longitudeDegrees
        let hourAngleDegrees = normalizeSignedDegrees(trueSolarMinutes / 4 - 180)
        let hourAngle = degreesToRadians(hourAngleDegrees)
        let latitude = degreesToRadians(latitudeDegrees)

        let cosZenith = clamp(
            sin(latitude) * sin(parameters.declinationRadians)
                + cos(latitude) * cos(parameters.declinationRadians) * cos(hourAngle),
            minimum: -1,
            maximum: 1
        )
        let zenith = acos(cosZenith)
        let altitude = 90 - radiansToDegrees(zenith)

        let azimuthRadians = atan2(
            sin(hourAngle),
            cos(hourAngle) * sin(latitude)
                - tan(parameters.declinationRadians) * cos(latitude)
        )
        let azimuth = normalizeDegrees(radiansToDegrees(azimuthRadians) + 180)

        return HorizontalCoordinate(azimuth: azimuth, altitude: altitude)
    }

    /// Approximate geocentric Sun position in the rotating ECEF/PEF frame.
    ///
    /// NOAA's fractional-year equations provide declination and equation of time.
    /// At Greenwich, the negative solar hour angle is the subsolar longitude, which
    /// directly defines the Earth-fixed direction. A constant astronomical-unit
    /// distance is sufficient for the angular-disk shadow model; the annual distance
    /// variation changes the Sun's angular radius by only a few thousandths of a degree.
    static func solarPositionEarthFixed(date: Date) -> EarthFixedPosition {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let parameters = approximateSolarParameters(date: date, calendar: calendar)
        let greenwichHourAngleDegrees = normalizeSignedDegrees(
            (parameters.fractionalHour * 60 + parameters.equationOfTimeMinutes) / 4 - 180
        )
        let subsolarLongitude = degreesToRadians(-greenwichHourAngleDegrees)
        let equatorialProjection = astronomicalUnitKilometers * cos(parameters.declinationRadians)

        return EarthFixedPosition(
            xKilometers: equatorialProjection * cos(subsolarLongitude),
            yKilometers: equatorialProjection * sin(subsolarLongitude),
            zKilometers: astronomicalUnitKilometers * sin(parameters.declinationRadians)
        )
    }

    static func twilightState(solarAltitudeDegrees: Double) -> TwilightState {
        switch solarAltitudeDegrees {
        case 0...:
            return .daylight
        case -6..<0:
            return .civil
        case -12..<(-6):
            return .nautical
        case -18..<(-12):
            return .astronomical
        default:
            return .night
        }
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

    private static func clamp(_ value: Double, minimum: Double, maximum: Double) -> Double {
        min(maximum, max(minimum, value))
    }

    private struct ApproximateSolarParameters {
        let fractionalHour: Double
        let equationOfTimeMinutes: Double
        let declinationRadians: Double
    }

    private static func approximateSolarParameters(
        date: Date,
        calendar: Calendar
    ) -> ApproximateSolarParameters {
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: date)?.count ?? 365
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)
        let fractionalHour = hour + minute / 60 + second / 3600
        let gamma = 2 * Double.pi / Double(daysInYear)
            * (Double(dayOfYear - 1) + (fractionalHour - 12) / 24)
        let equationOfTime = 229.18 * (
            0.000075
            + 0.001868 * cos(gamma)
            - 0.032077 * sin(gamma)
            - 0.014615 * cos(2 * gamma)
            - 0.040849 * sin(2 * gamma)
        )
        let declination = 0.006918
            - 0.399912 * cos(gamma)
            + 0.070257 * sin(gamma)
            - 0.006758 * cos(2 * gamma)
            + 0.000907 * sin(2 * gamma)
            - 0.002697 * cos(3 * gamma)
            + 0.00148 * sin(3 * gamma)

        return ApproximateSolarParameters(
            fractionalHour: fractionalHour,
            equationOfTimeMinutes: equationOfTime,
            declinationRadians: declination
        )
    }

    private static func degreesToRadians(_ degrees: Double) -> Double { degrees * .pi / 180 }
    private static func radiansToDegrees(_ radians: Double) -> Double { radians * 180 / .pi }
}
