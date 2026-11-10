//
//  VistaClockTests.swift
//  VistaClockTests
//
//  Copyright © 2026 Mazookie, LLC. All rights reserved.
//

import AppKit
import Foundation
import Testing
@testable import VistaClock

/// Tests for the calendar control and the clock face.
@MainActor
struct VistaClockTests {
    private func makeCalendar(on date: Date) -> MZCalendarControl {
        let calendar = MZCalendarControl(frame: NSRect(x: 0, y: 0, width: 290, height: 214))
        calendar.setDate(date)
        return calendar
    }

    @Test func calendarSelectsTheGivenDay() {
        let calendar = makeCalendar(on: Date.noon(year: 2026, month: 2, day: 28))
        #expect(calendar.selectedDate.year == 2026)
        #expect(calendar.selectedDate.month == 2)
        #expect(calendar.selectedDate.day == 28)
    }

    @Test func calendarMovesBetweenMonths() {
        let calendar = makeCalendar(on: Date.noon(year: 2026, month: 12, day: 15))
        calendar.nextMonth()
        #expect(calendar.selectedDate.year == 2027)
        #expect(calendar.selectedDate.month == 1)

        calendar.lastMonth()
        calendar.lastMonth()
        #expect(calendar.selectedDate.year == 2026)
        #expect(calendar.selectedDate.month == 11)
    }

    @Test func calendarClampsToTheEndOfShorterMonths() {
        let calendar = makeCalendar(on: Date.noon(year: 2026, month: 1, day: 31))
        calendar.nextMonth()
        #expect(calendar.selectedDate.month == 2)
        #expect(calendar.selectedDate.day == 28)
    }

    @Test func calendarKeepsNoonSoTheDayNeverShifts() {
        let calendar = makeCalendar(on: Date.noon(year: 2026, month: 3, day: 8)) // US daylight saving starts
        #expect(Calendar.current.component(.hour, from: calendar.selectedDate) == 12)
        calendar.nextMonth()
        #expect(Calendar.current.component(.hour, from: calendar.selectedDate) == 12)
    }

    @Test func clockFaceFallsBackToTheDefaultFace() {
        let clock = MZClockControl(frame: NSRect(x: 0, y: 0, width: 138, height: 138))
        clock.setClockFace(named: "does-not-exist.png")
        #expect(clock.clockFaceName == "VCB01.png")
    }

    @Test func clockOnlyRedrawsWhenTheTimeChanges() {
        let clock = MZClockControl(frame: NSRect(x: 0, y: 0, width: 138, height: 138))
        let time = Date.noon(year: 2026, month: 11, day: 10)
        clock.setTime(time)
        #expect(clock.time == time)

        clock.setTime(time.addingTimeInterval(60))
        #expect(clock.time == time.addingTimeInterval(60))
    }

    @Test func clockRendersAnImage() {
        let clock = MZClockControl(frame: NSRect(x: 0, y: 0, width: 138, height: 138))
        #expect(clock.renderedImage() != nil)
    }
}
