import Foundation

struct SkyCalendarDay: Identifiable, Hashable {
    let date: Date
    let events: [SkyEvent]
    var id: Date { Calendar.current.startOfDay(for: date) }

    var bestScore: Int? {
        guard !events.isEmpty else { return nil }
        return events.map { Int(($0.baseImportance * 100).rounded()) }.max()
    }
}

enum SkyCalendarBuilder {
    static func days(containing events: [SkyEvent], around date: Date = Date(), count: Int = 30) -> [SkyCalendarDay] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        return (0..<count).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start),
                  let next = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
            let matches = events.filter { $0.startDate >= day && $0.startDate < next }
            return SkyCalendarDay(date: day, events: matches)
        }
    }
}
