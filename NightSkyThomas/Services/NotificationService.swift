import Foundation
import UserNotifications

@MainActor
final class SkyNotificationService {
    static let shared = SkyNotificationService()

    private init() {}

    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedule(event: SkyEvent, score: SkyScoreResult, leadMinutes: Int) async throws {
        guard score.score >= 70 else { return }

        let fireDate = event.startDate.addingTimeInterval(TimeInterval(-leadMinutes * 60))
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Naar buiten? \(event.title) komt eraan"
        content.body = notificationBody(event: event, score: score)
        content.sound = .default
        content.userInfo = ["skyEventID": event.id.uuidString]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "sky-event-\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    func cancel(event: SkyEvent) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["sky-event-\(event.id.uuidString)"]
        )
    }

    private func notificationBody(event: SkyEvent, score: SkyScoreResult) -> String {
        var parts = ["Sky Score \(score.score)/100", "zichtkans \(score.visibilityChance)%"]
        if let elevation = event.elevationDegrees {
            parts.append("max. hoogte \(Int(elevation))°")
        }
        if let magnitude = event.magnitude {
            parts.append(String(format: "helderheid %.1f mag", magnitude))
        }
        return parts.joined(separator: " · ")
    }
}
