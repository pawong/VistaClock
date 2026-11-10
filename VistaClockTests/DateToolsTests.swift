//
//  DateToolsTests.swift
//  VistaClockTests
//
//  Copyright © 2026 Mazookie, LLC. All rights reserved.
//

import Foundation
import Testing
@testable import VistaClock

/// Tests for the Date helpers. They assume the system calendar is Gregorian, as the app does.
struct DateToolsTests {
    /// A date at the given local time on a Gregorian calendar.
    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, minute: Int = 0, second: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return Calendar.current.date(from: components)!
    }

    @Test func noonBuildsLocalNoon() {
        let noon = Date.noon(year: 2026, month: 11, day: 10)
        #expect(noon.year == 2026)
        #expect(noon.month == 11)
        #expect(noon.day == 10)
        #expect(Calendar.current.component(.hour, from: noon) == 12)
    }

    @Test func noonOfDayKeepsTheDayAndDropsTheTime() {
        let evening = date(2026, 3, 8, hour: 23, minute: 59, second: 59)
        let noon = evening.noonOfDay
        #expect(noon.day == 8)
        #expect(Calendar.current.component(.hour, from: noon) == 12)
        #expect(Calendar.current.component(.minute, from: noon) == 0)
        #expect(noon.noonOfDay == noon)
    }

    @Test func settingTimeKeepsTheDay() {
        let result = date(2026, 11, 10).setting24Hour(hour: 17, minute: 45, second: 30)
        #expect(result.day == 10)
        #expect(Calendar.current.component(.hour, from: result) == 17)
        #expect(result.minutes == 45)
        #expect(result.seconds == 30)
    }

    @Test(arguments: [(0, 12), (1, 1), (11, 11), (12, 12), (13, 1), (23, 11)])
    func hoursUseATwelveHourClock(hour24: Int, expected: Int) {
        #expect(date(2026, 11, 10, hour: hour24).hours == expected)
    }

    @Test func usDayOfWeekStartsOnSunday() {
        #expect(date(2026, 11, 8).usDayOfWeek == 1)  // Sunday
        #expect(date(2026, 11, 10).usDayOfWeek == 3) // Tuesday
        #expect(date(2026, 11, 14).usDayOfWeek == 7) // Saturday
    }

    @Test func isoWeekNumbersFollowISO8601() {
        #expect(date(2026, 1, 1).isoWeekNumber == 1)   // Thursday: week 1
        #expect(date(2024, 12, 30).isoWeekNumber == 1) // Monday that belongs to 2025's week 1
        #expect(date(2021, 1, 3).isoWeekNumber == 53)  // Sunday that still belongs to 2020
        #expect(date(2026, 11, 10).isoWeekNumberString == "46")
    }

    @Test func dayStringsAreNotPadded() {
        #expect(date(2026, 11, 5).dayString == "5")
        #expect(date(2026, 2, 1).dayOfYearString == "32")
    }

    @Test func formattedStringsHaveContent() {
        let now = date(2026, 11, 10, hour: 15, minute: 4, second: 9)
        #expect(!now.monthString.isEmpty)
        #expect(!now.dayOfWeekString.isEmpty)
        #expect(!now.monthYearString.isEmpty)
        #expect(now.time24String.hasPrefix("15"))
        #expect(!now.dayNameShortString.isEmpty)
    }
}
