import CoreLocation
import Foundation

struct ObserverLocation: Hashable, Sendable {
    let latitude: Double
    let longitude: Double
    let altitudeMeters: Double

    init(latitude: Double, longitude: Double, altitudeMeters: Double = 0) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeMeters = altitudeMeters
    }

    init(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        altitudeMeters = location.verticalAccuracy >= 0 ? location.altitude : 0
    }
}
