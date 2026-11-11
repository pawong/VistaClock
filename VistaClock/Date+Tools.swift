//
//  Date+Tools.swift
//  VistaClock
//
//  Created by Paul Wong on 1/22/12.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

import Foundation

/// Hands out DateFormatters keyed by pattern so we don't rebuild one for every call.
private final class FormatterCache: @unchecked Sendable {
    static let shared = FormatterCache()

    private let lock = NSLock()
    private var formatters: [String: DateFormatter] = [:]
    private var localeIdentifier: String?

    func string(from date: Date, pattern: String) -> String {
        lock.lock()
        defer { lock.unlock() }

        // Rebuild everything if the user's preferred language changed.
        let current = Locale.preferredLanguages.first ?? "en_US"
        if current != localeIdentifier {
            formatters.removeAll()
            localeIdentifier = current
        }

        let formatter: DateFormatter
        if let cached = formatters[pattern] {
            formatter = cached
        } else {
            formatter = DateFormatter()
            formatter.locale = Locale(identifier: current)
            formatter.dateFormat = pattern
            formatters[pattern] = formatter
        }
        return formatter.string(from: date)
    }
}

extension Date {
    // MARK: - Construction

    /// Local noon on the given year/month/day. Noon keeps the value on the same
    /// calendar day regardless of DST or time zone shifts.
    static func noon(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components) ?? Date()
    }

    /// Local noon of the day this date falls on.
    var noonOfDay: Date {
        Date.noon(year: year, month: month, day: day)
    }

    /// Replaces the time of day, keeping the year/month/day.
    func setting24Hour(hour: Int, minute: Int, second: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        components.hour = hour
        components.minute = minute
        components.second = second
        return Calendar.current.date(from: components) ?? self
    }

    // MARK: - Numeric parts

    var year: Int { Calendar.current.component(.year, from: self) }
    var month: Int { Calendar.current.component(.month, from: self) }
    var day: Int { Calendar.current.component(.day, from: self) }

    /// Hour on a 12-hour clock (1...12).
    var hours: Int {
        let hour = Calendar.current.component(.hour, from: self) % 12
        return hour == 0 ? 12 : hour
    }

    var minutes: Int { Calendar.current.component(.minute, from: self) }
    var seconds: Int { Calendar.current.component(.second, from: self) }

    /// Day of the week with Sunday = 1, regardless of the user's locale.
    var usDayOfWeek: Int {
        Calendar(identifier: .gregorian).component(.weekday, from: self)
    }

    var weekNumber: Int { Calendar.current.component(.weekOfYear, from: self) }

    var isoWeekNumber: Int {
        Calendar(identifier: .iso8601).component(.weekOfYear, from: self)
    }

    // MARK: - Strings

    private func formatted(_ pattern: String) -> String {
        FormatterCache.shared.string(from: self, pattern: pattern)
    }

    var monthString: String { formatted("MMMM") }
    var dayOfWeekString: String { formatted("EEEE") }
    var timeString: String { formatted("h:mm:ss a") }
    var time24String: String { formatted("HH:mm:ss") }
    var ampmString: String { formatted("a") }
    var monthYearString: String { formatted("MMMM yyyy") }
    var dateTimeString: String { formatted("EEEE MMMM d, yyyy h:mm:ss a") }
    var dateString: String { formatted("EEEE  MMMM d, yyyy") }
    var weekNumberString: String { formatted("w") }
    var isoWeekNumberString: String { String(isoWeekNumber) }
    var dayNameShortString: String { formatted("EEEEE") }
    var dayString: String { formatted("d") }
    var dayOfYearString: String { formatted("D") }
}

extension Date {
    /// The time in words, rounded to five minutes, e.g. "Quarter past Three" or "Ten to Twelve".
    var fuzzyTimeString: String {
        let hourNames = ["One", "Two", "Three", "Four", "Five", "Six",
                         "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"]
        let messages = [
            "%@ o'clock", "Five past %@", "Ten past %@", "Quarter past %@",
            "Twenty past %@", "Twenty Five past %@", "Half past %@", "Twenty Five to %@",
            "Twenty to %@", "Quarter to %@", "Ten to %@", "Five to %@",
        ]

        let components = Calendar.current.dateComponents([.hour, .minute], from: self)
        var hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        var index = 0
        if minutes > 2 {
            index = (minutes - 3) / 5 + 1
        }
        if hours < 1 {
            hours = 12
        }
        // past the half hour the words count up to the next hour
        if minutes > 32 {
            hours += 1
        }
        return String(format: messages[index % 12], hourNames[(hours - 1) % 12])
    }
}

extension Calendar {
    /// Identifier of the calendar the user's locale prefers.
    static var userCalendarIdentifier: Calendar.Identifier {
        Locale.current.calendar.identifier
    }

    /// True when the user's calendar can be drawn by the custom calendar control.
    static var userCalendarIsGregorianStyle: Bool {
        userCalendarIdentifier == .gregorian || userCalendarIdentifier == .iso8601
    }
}
