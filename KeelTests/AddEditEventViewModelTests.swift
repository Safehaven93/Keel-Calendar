import XCTest
@testable import Keel

final class AddEditEventViewModelTests: XCTestCase {
    private let calendar = Calendar.current

    private func date(hour: Int, minute: Int) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: .now)!
    }

    func testRoundsUpPastHalfHourToNextHour() {
        // 6:17 + 1hr = 7:17 in the real flow; the example from the report.
        let rounded = AddEditEventViewModel.roundedUpToNextHalfHour(date(hour: 19, minute: 17), calendar: calendar)
        XCTAssertEqual(rounded, date(hour: 19, minute: 30))
    }

    func testRoundsUpPastTheHourToNextHalfHour() {
        let rounded = AddEditEventViewModel.roundedUpToNextHalfHour(date(hour: 19, minute: 45), calendar: calendar)
        XCTAssertEqual(rounded, date(hour: 20, minute: 0))
    }

    func testLeavesExactHalfHourUnchanged() {
        let rounded = AddEditEventViewModel.roundedUpToNextHalfHour(date(hour: 19, minute: 30), calendar: calendar)
        XCTAssertEqual(rounded, date(hour: 19, minute: 30))
    }

    func testLeavesExactHourUnchanged() {
        let rounded = AddEditEventViewModel.roundedUpToNextHalfHour(date(hour: 19, minute: 0), calendar: calendar)
        XCTAssertEqual(rounded, date(hour: 19, minute: 0))
    }
}
