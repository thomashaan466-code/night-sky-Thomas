import Foundation

struct SkyEvent: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let type: SkyEventType
    let startDate: Date
    let endDate: Date?
    let azimuthDegrees: Double?
    let elevationDegrees: Double?
    let magnitude: Double?
    let baseImportance: Double
    let summary: String
    let sourceName: String

    init(
        id: UUID = UUID(),
        title: String,
        type: SkyEventType,
        startDate: Date,
        endDate: Date? = nil,
        azimuthDegrees: Double? = nil,
        elevationDegrees: Double? = nil,
        magnitude: Double? = nil,
        baseImportance: Double,
        summary: String,
        sourceName: String
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.azimuthDegrees = azimuthDegrees
        self.elevationDegrees = elevationDegrees
        self.magnitude = magnitude
        self.baseImportance = baseImportance
        self.summary = summary
        self.sourceName = sourceName
    }
}

enum SkyEventType: String, Codable, CaseIterable {
    case iss
    case satellite
    case starlink
    case aurora
    case meteor
    case planet
    case moon
    case comet
    case eclipse
    case rocket

    var symbolName: String {
        switch self {
        case .iss, .satellite, .starlink: return "dot.radiowaves.left.and.right"
        case .aurora: return "sparkles"
        case .meteor: return "wand.and.stars"
        case .planet: return "circle.circle"
        case .moon: return "moon.stars.fill"
        case .comet: return "sparkle"
        case .eclipse: return "circle.lefthalf.filled"
        case .rocket: return "airplane"
        }
    }
}
