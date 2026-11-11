//
//  FuzzyTimeTests.swift
//  VistaClockTests
//
//  Copyright © 2026 Mazookie, LLC. All rights reserved.
//

import Foundation
import Testing
@testable import VistaClock

/// Tests for the "fuzzy time" menu bar text.
struct FuzzyTimeTests {
    private func fuzzy(_ hour: Int, _ minute: Int) -> String {
        var components = DateComponents()
        components.year = 2026
        components.month = 11
        components.day = 10
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!.fuzzyTimeString
    }

    @Test(arguments: [
        (3, 0, "Three o'clock"),
        (3, 2, "Three o'clock"),
        (3, 3, "Five past Three"),
        (3, 8, "Ten past Three"),
        (3, 15, "Quarter past Three"),
        (3, 20, "Twenty past Three"),
        (3, 25, "Twenty Five past Three"),
        (3, 30, "Half past Three"),
        (3, 32, "Half past Three"),
        (3, 35, "Twenty Five to Four"),
        (3, 40, "Twenty to Four"),
        (3, 45, "Quarter to Four"),
        (3, 50, "Ten to Four"),
        (3, 55, "Five to Four"),
    ])
    func readsTheMinutesInWords(hour: Int, minute: Int, expected: String) {
        #expect(fuzzy(hour, minute) == expected)
    }

    @Test func midnightIsTwelve() {
        #expect(fuzzy(0, 0) == "Twelve o'clock")
        #expect(fuzzy(0, 15) == "Quarter past Twelve")
    }

    @Test func noonIsTwelve() {
        #expect(fuzzy(12, 0) == "Twelve o'clock")
    }

    @Test func afternoonHoursUseTheTwelveHourNames() {
        #expect(fuzzy(15, 15) == "Quarter past Three")
        #expect(fuzzy(23, 15) == "Quarter past Eleven")
    }

    @Test func roundsUpToTheNextHourNearTheTop() {
        #expect(fuzzy(12, 58) == "One o'clock")
        #expect(fuzzy(23, 58) == "Twelve o'clock")
        #expect(fuzzy(23, 50) == "Ten to Twelve")
    }
}
