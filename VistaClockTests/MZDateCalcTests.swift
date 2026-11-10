//
//  MZDateCalcTests.swift
//  VistaClockTests
//
//  Copyright © 2026 Mazookie, LLC. All rights reserved.
//

import AppKit
import Foundation
import Testing
@testable import VistaClock

/// Tests for the "go to date" expressions, run against a real calendar control.
/// The control starts on Tuesday, November 10, 2026.
@MainActor
struct MZDateCalcTests {
    private let calendar: MZCalendarControl
    private let calc = MZDateCalc()

    init() {
        calendar = MZCalendarControl(frame: NSRect(x: 0, y: 0, width: 290, height: 214))
        calendar.setDate(Date.noon(year: 2026, month: 11, day: 10))
        calc.calendar = calendar
    }

    /// Whether the control is showing year/month/day.
    private func isSelected(_ year: Int, _ month: Int, _ day: Int) -> Bool {
        Calendar.current.isDate(calendar.selectedDate, inSameDayAs: Date.noon(year: year, month: month, day: day))
    }

    @Test func movesByDays() {
        calc.moveDate("5d", useToday: false)
        #expect(isSelected(2026, 11, 15))
    }

    @Test func movesBackwardsByDays() {
        calc.moveDate("-10d", useToday: false)
        #expect(isSelected(2026, 10, 31))
    }

    @Test func movesByWeeks() {
        calc.moveDate("2w", useToday: false)
        #expect(isSelected(2026, 11, 24))
    }

    @Test func movesByMonths() {
        calc.moveDate("3m", useToday: false)
        #expect(isSelected(2027, 2, 10))
    }

    @Test func movesByYears() {
        calc.moveDate("1y", useToday: false)
        #expect(isSelected(2027, 11, 10))
    }

    @Test func goesToDayOfTheYear() {
        calc.moveDate("d100", useToday: false)
        #expect(isSelected(2026, 4, 10))
    }

    @Test func ignoresOutOfRangeDayOfTheYear() {
        calc.moveDate("d400", useToday: false)
        #expect(isSelected(2026, 11, 10))
    }

    @Test func fiveDayBusinessWeekSkipsWeekends() {
        // Wed, Thu, Fri, Mon, Tue
        calc.moveDate("5b5", useToday: false)
        #expect(isSelected(2026, 11, 17))
    }

    @Test func sixDayBusinessWeekOnlySkipsSundays() {
        // Wed, Thu, Fri, Sat, (Sunday skipped) Mon
        calc.moveDate("5b6", useToday: false)
        #expect(isSelected(2026, 11, 16))
    }

    @Test func businessDaysCanGoBackwards() {
        // Mon, Fri, Thu
        calc.moveDate("-3b5", useToday: false)
        #expect(isSelected(2026, 11, 5))
    }

    @Test func unrecognizedTextDoesNotMove() {
        calc.moveDate("hello", useToday: false)
        #expect(isSelected(2026, 11, 10))
    }

    @Test func movesFromTodayWhenAsked() {
        calc.moveDate("0d", useToday: true) // zero is "no move"
        #expect(isSelected(2026, 11, 10))

        calc.moveDate("1d", useToday: true)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        #expect(Calendar.current.isDate(calendar.selectedDate, inSameDayAs: tomorrow))
    }

    @Test func parsesTheTodayShortcut() {
        #expect(calc.parseDate("t"))
        #expect(Calendar.current.isDateInToday(calendar.selectedDate))
    }

    @Test func parsesDatesInTheShortStyleOfTheCurrentLocale() {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .short
        let text = formatter.string(from: Date.noon(year: 2026, month: 7, day: 4))

        #expect(calc.parseDate(text))
        #expect(isSelected(2026, 7, 4))
    }

    @Test func rejectsTextThatIsNotADate() {
        #expect(!calc.parseDate("xyz"))
        #expect(isSelected(2026, 11, 10))
    }
}
