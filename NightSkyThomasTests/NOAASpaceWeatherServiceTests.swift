import XCTest
@testable import NightSkyThomas

final class NOAASpaceWeatherServiceTests: XCTestCase {
    func testDecodesCurrentSWPCSchemaAndTreatsTimeTagAsUTC() throws {
        let data = Data("""
        [
          {"time_tag":"2026-09-16T16:14:00","kp_index":1,"estimated_kp":0.67,"kp":"1M"},
          {"time_tag":"2026-09-16T16:15:00","kp_index":2,"estimated_kp":1.67,"kp":"2M"}
        ]
        """.utf8)

        let snapshot = try NOAASpaceWeatherService.decodeSnapshot(from: data)

        XCTAssertEqual(snapshot.kp, 1.67)
        XCTAssertEqual(snapshot.measuredAt, makeUTCDate(
            year: 2026,
            month: 9,
            day: 16,
            hour: 16,
            minute: 15
        ))
    }

    func testChoosesNewestTimestampInsteadOfAssumingResponseOrder() throws {
        let data = Data("""
        [
          {"time_tag":"2026-09-16T16:15:00.000","kp_index":2,"estimated_kp":1.67,"kp":"2M"},
          {"time_tag":"2026-09-16T16:14:00.000","kp_index":1,"estimated_kp":0.67,"kp":"1M"}
        ]
        """.utf8)

        let snapshot = try NOAASpaceWeatherService.decodeSnapshot(from: data)

        XCTAssertEqual(snapshot.kp, 1.67)
        XCTAssertEqual(snapshot.measuredAt, makeUTCDate(
            year: 2026,
            month: 9,
            day: 16,
            hour: 16,
            minute: 15
        ))
    }

    func testRejectsRowsWhoseTimestampsCannotBeInterpreted() {
        let data = Data("""
        [{"time_tag":"not-a-date","kp_index":1,"estimated_kp":0.67,"kp":"1M"}]
        """.utf8)

        XCTAssertThrowsError(try NOAASpaceWeatherService.decodeSnapshot(from: data))
    }

    private func makeUTCDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }
}
