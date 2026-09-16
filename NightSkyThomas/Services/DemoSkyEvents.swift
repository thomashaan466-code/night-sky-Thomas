import Foundation

enum DemoSkyEvents {
    static var upcoming: [SkyEvent] {
        let calendar = Calendar.current
        let now = Date()

        return [
            SkyEvent(
                title: "ISS overhead",
                type: .iss,
                startDate: calendar.date(byAdding: .minute, value: 18, to: now)!,
                endDate: calendar.date(byAdding: .minute, value: 24, to: now),
                azimuthDegrees: 270,
                elevationDegrees: 84,
                magnitude: -3.2,
                baseImportance: 0.98,
                summary: "Een zeer hoge passage. Kijk eerst naar het westen en volg het heldere, niet-knipperende lichtpunt.",
                sourceName: "Demo / CelesTrak planned"
            ),
            SkyEvent(
                title: "Saturnus",
                type: .planet,
                startDate: calendar.date(byAdding: .hour, value: 2, to: now)!,
                azimuthDegrees: 118,
                elevationDegrees: 32,
                magnitude: 0.6,
                baseImportance: 0.58,
                summary: "Goed zichtbaar bij een heldere hemel. Met een telescoop zijn de ringen het hoogtepunt.",
                sourceName: "Local astronomy engine planned"
            ),
            SkyEvent(
                title: "Aurora watch",
                type: .aurora,
                startDate: calendar.date(byAdding: .hour, value: 4, to: now)!,
                azimuthDegrees: 0,
                elevationDegrees: 15,
                baseImportance: 0.82,
                summary: "Alleen tonen als ruimteweer sterk genoeg is voor een realistische kans vanuit Zeeland.",
                sourceName: "NOAA SWPC planned"
            )
        ]
    }
}
