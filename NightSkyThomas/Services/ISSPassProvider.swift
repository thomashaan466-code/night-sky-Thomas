import Foundation

actor ISSPassProvider {
    static let issCatalogNumber = 25544

    private let tleService: TLEProviding
    private let passService: SatellitePassProviding

    init(
        tleService: TLEProviding = CelesTrakTLEService(),
        passService: SatellitePassProviding = SatellitePassService()
    ) {
        self.tleService = tleService
        self.passService = passService
    }

    func nextPasses(
        observer: ObserverLocation,
        from start: Date = .now,
        hours: Double = 48,
        minimumElevation: Double = 10
    ) async throws -> [SatellitePass] {
        let tle = try await tleService.tle(catalogNumber: Self.issCatalogNumber)
        return try passService.passes(
            tleRecord: tle,
            observer: observer,
            from: start,
            through: start.addingTimeInterval(hours * 3600),
            minimumElevation: minimumElevation
        )
    }
}
