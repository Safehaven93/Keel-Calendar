import XCTest
import SwiftData
@testable import Keel

final class AgendaViewModelTests: XCTestCase {
    private func event(_ title: String, daysFromNow: Int, hour: Int = 12) -> Event {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: daysFromNow, to: .now)!
        let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        return Event(title: title, startDate: start, endDate: start.addingTimeInterval(3600))
    }

    // MARK: - events(on:from:)

    func testEventsOnDayMatchesSameCalendarDay() {
        let today = event("Today", daysFromNow: 0, hour: 9)
        let tomorrow = event("Tomorrow", daysFromNow: 1, hour: 9)
        let viewModel = AgendaViewModel(modelContext: makeInMemoryContext())

        let result = viewModel.events(on: .now, from: [today, tomorrow])

        XCTAssertEqual(result.map(\.title), ["Today"])
    }

    func testEventsOnDayExcludesOtherDays() {
        let yesterday = event("Yesterday", daysFromNow: -1)
        let viewModel = AgendaViewModel(modelContext: makeInMemoryContext())

        let result = viewModel.events(on: .now, from: [yesterday])

        XCTAssertTrue(result.isEmpty)
    }

    func testEventsOnDaySortedByStartTime() {
        let later = event("Later", daysFromNow: 0, hour: 15)
        let earlier = event("Earlier", daysFromNow: 0, hour: 8)
        let viewModel = AgendaViewModel(modelContext: makeInMemoryContext())

        let result = viewModel.events(on: .now, from: [later, earlier])

        XCTAssertEqual(result.map(\.title), ["Earlier", "Later"])
    }

    // MARK: - dayRange(around:days:)

    func testDayRangeCount() {
        let range = AgendaViewModel.dayRange(around: .now, days: 5)
        XCTAssertEqual(range.count, 11)
    }

    func testDayRangeCenterIsGivenDate() {
        let calendar = Calendar.current
        let center = calendar.startOfDay(for: .now)
        let range = AgendaViewModel.dayRange(around: center, days: 5)

        XCTAssertEqual(range[5], center)
    }

    func testDayRangeFirstAndLastAreExactlyDaysAway() {
        let calendar = Calendar.current
        let center = calendar.startOfDay(for: .now)
        let range = AgendaViewModel.dayRange(around: center, days: 5)

        XCTAssertEqual(range.first, calendar.date(byAdding: .day, value: -5, to: center))
        XCTAssertEqual(range.last, calendar.date(byAdding: .day, value: 5, to: center))
    }

    private func makeInMemoryContext() -> ModelContext {
        let container = try! ModelContainer(for: Event.self, configurations: .init(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }
}
