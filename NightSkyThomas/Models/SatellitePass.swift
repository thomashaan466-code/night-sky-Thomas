import Foundation

struct LookAngle: Hashable, Sendable {
    let date: Date
    let azimuthDegrees: Double
    let elevationDegrees: Double
    let rangeKilometers: Double
}

struct SatellitePass: Identifiable, Hashable, Sendable {
    let id: UUID
    let satelliteName: String
    let rise: LookAngle
    let culmination: LookAngle
    let setAngle: LookAngle

    init(
        id: UUID = UUID(),
        satelliteName: String,
        rise: LookAngle,
        culmination: LookAngle,
        set: LookAngle
    ) {
        self.id = id
        self.satelliteName = satelliteName
        self.rise = rise
        self.culmination = culmination
        self.setAngle = set
    }

    var duration: TimeInterval {
        setAngle.date.timeIntervalSince(rise.date)
    }
}
