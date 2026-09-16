import Foundation
import SwiftSGP4

protocol SatellitePassProviding {
    func passes(
        tleRecord: TLERecord,
        observer: ObserverLocation,
        from start: Date,
        through end: Date,
        minimumElevation: Double
    ) throws -> [SatellitePass]
}

struct SatellitePassService: SatellitePassProviding {
    private let scanStep: TimeInterval = 20
    private let refinementIterations = 18

    func passes(
        tleRecord: TLERecord,
        observer: ObserverLocation,
        from start: Date,
        through end: Date,
        minimumElevation: Double = 10
    ) throws -> [SatellitePass] {
        guard end > start else { return [] }

        let tle = try TLE(name: tleRecord.name, lineOne: tleRecord.line1, lineTwo: tleRecord.line2)
        let propagator = try PropagatorFactory.create(tle: tle)
        let epoch = tleEpoch(from: tleRecord.line1)

        func look(at date: Date) throws -> LookAngle {
            let minutes = date.timeIntervalSince(epoch) / 60
            let state = try propagator.propagate(minutesSinceEpoch: minutes)
            let (ecef, _) = CoordinateConverter.temeToECEF(
                position: state.position,
                velocity: state.velocity,
                date: date
            )
            return topocentricLookAngle(ecef: ecef, observer: observer, date: date)
        }

        var result: [SatellitePass] = []
        var previousDate = start
        var previous = try look(at: start)
        var activeRise: LookAngle? = previous.elevationDegrees >= minimumElevation ? previous : nil
        var activePeak: LookAngle? = activeRise

        var date = start.addingTimeInterval(scanStep)
        while date <= end {
            let current = try look(at: date)

            if activeRise == nil,
               previous.elevationDegrees < minimumElevation,
               current.elevationDegrees >= minimumElevation {
                let riseDate = try refineCrossing(
                    lower: previousDate,
                    upper: date,
                    targetElevation: minimumElevation,
                    look: look
                )
                let rise = try look(at: riseDate)
                activeRise = rise
                activePeak = rise
            }

            if activeRise != nil,
               current.elevationDegrees > (activePeak?.elevationDegrees ?? -.infinity) {
                activePeak = current
            }

            if let rise = activeRise,
               previous.elevationDegrees >= minimumElevation,
               current.elevationDegrees < minimumElevation {
                let setDate = try refineCrossing(
                    lower: previousDate,
                    upper: date,
                    targetElevation: minimumElevation,
                    look: look
                )
                let set = try look(at: setDate)
                let peak = try refinePeak(
                    around: activePeak?.date ?? previousDate,
                    look: look
                )
                result.append(SatellitePass(
                    satelliteName: tleRecord.name,
                    rise: rise,
                    culmination: peak,
                    set: set
                ))
                activeRise = nil
                activePeak = nil
            }

            previousDate = date
            previous = current
            date = date.addingTimeInterval(scanStep)
        }

        return result
    }

    private func topocentricLookAngle(ecef: Vector3D, observer: ObserverLocation, date: Date) -> LookAngle {
        let lat = observer.latitude * .pi / 180
        let lon = observer.longitude * .pi / 180
        let altitudeKm = observer.altitudeMeters / 1000

        let a = 6378.137
        let e2 = 6.69437999014e-3
        let sinLat = sin(lat)
        let cosLat = cos(lat)
        let n = a / sqrt(1 - e2 * sinLat * sinLat)

        let ox = (n + altitudeKm) * cosLat * cos(lon)
        let oy = (n + altitudeKm) * cosLat * sin(lon)
        let oz = (n * (1 - e2) + altitudeKm) * sinLat

        let dx = ecef.x - ox
        let dy = ecef.y - oy
        let dz = ecef.z - oz

        let east = -sin(lon) * dx + cos(lon) * dy
        let north = -sinLat * cos(lon) * dx - sinLat * sin(lon) * dy + cosLat * dz
        let up = cosLat * cos(lon) * dx + cosLat * sin(lon) * dy + sinLat * dz

        let range = sqrt(east * east + north * north + up * up)
        var azimuth = atan2(east, north) * 180 / .pi
        if azimuth < 0 { azimuth += 360 }
        let elevation = asin(up / range) * 180 / .pi

        return LookAngle(
            date: date,
            azimuthDegrees: azimuth,
            elevationDegrees: elevation,
            rangeKilometers: range
        )
    }

    private func refineCrossing(
        lower: Date,
        upper: Date,
        targetElevation: Double,
        look: (Date) throws -> LookAngle
    ) throws -> Date {
        var low = lower
        var high = upper
        let lowStartsBelow = try look(low).elevationDegrees < targetElevation

        for _ in 0..<refinementIterations {
            let mid = low.addingTimeInterval(high.timeIntervalSince(low) / 2)
            let midBelow = try look(mid).elevationDegrees < targetElevation
            if midBelow == lowStartsBelow { low = mid } else { high = mid }
        }
        return low.addingTimeInterval(high.timeIntervalSince(low) / 2)
    }

    private func refinePeak(
        around center: Date,
        look: (Date) throws -> LookAngle
    ) throws -> LookAngle {
        var low = center.addingTimeInterval(-scanStep)
        var high = center.addingTimeInterval(scanStep)

        for _ in 0..<refinementIterations {
            let span = high.timeIntervalSince(low)
            let left = low.addingTimeInterval(span / 3)
            let right = high.addingTimeInterval(-span / 3)
            if try look(left).elevationDegrees < look(right).elevationDegrees {
                low = left
            } else {
                high = right
            }
        }
        return try look(low.addingTimeInterval(high.timeIntervalSince(low) / 2))
    }

    private func tleEpoch(from line1: String) -> Date {
        // TLE epoch occupies columns 19–32: YYDDD.DDDDDDDD.
        let start = line1.index(line1.startIndex, offsetBy: 18)
        let end = line1.index(start, offsetBy: 14)
        let raw = String(line1[start..<end])
        let yy = Int(raw.prefix(2)) ?? 0
        let day = Double(raw.dropFirst(2)) ?? 1
        let year = yy < 57 ? 2000 + yy : 1900 + yy

        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = 1
        components.day = 1
        let jan1 = components.date ?? .distantPast
        return jan1.addingTimeInterval((day - 1) * 86_400)
    }
}
