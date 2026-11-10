//
//  MZDateCalc.swift
//  VistaClock
//
//  Created by Paul Wong on 1/10/16.
//  Copyright © 2026 Mazookie, LLC. All rights reserved.
//

import AppKit

/// Parses the "go to date" field: absolute dates, "t" for today and relative moves
/// such as `5d`, `-2w`, `3m`, `1y`, `w12`, `d200`, `10b5` and `10b6`.
@MainActor
final class MZDateCalc {
    private enum Unit {
        case day, week, month, year
    }

    weak var calendar: MZCalendarControl?

    // MARK: - Date math

    private func isBusinessDay(_ date: Date, fullWeek: Bool) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        let sunday = 1
        let saturday = 7
        return fullWeek ? (weekday != sunday && weekday != saturday) : (weekday != sunday)
    }

    private func addBusinessDays(to start: Date, days: Int, fullWeek: Bool) -> Date {
        var end = start
        var remaining = abs(days)
        let step = days < 0 ? -1 : 1
        while remaining > 0 {
            end = add(to: end, unit: .day, count: step)
            if isBusinessDay(end, fullWeek: fullWeek) {
                remaining -= 1
            }
        }
        return end
    }

    private func add(to date: Date, unit: Unit, count: Int) -> Date {
        var components = DateComponents()
        switch unit {
        case .day: components.day = count
        case .week: components.day = count * 7
        case .month: components.month = count
        case .year: components.year = count
        }
        return Calendar.current.date(byAdding: components, to: date) ?? date
    }

    // MARK: - Token parsing

    /// The first captured integer for `pattern`, or 0 when there is no match.
    private func firstNumber(matching pattern: String, in string: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return 0 }
        let range = NSRange(string.startIndex..., in: string)
        guard let match = regex.firstMatch(in: string, range: range),
              let captured = Range(match.range(at: 1), in: string) else { return 0 }
        return Int(string[captured]) ?? 0
    }

    private func days(_ input: String) -> Int { firstNumber(matching: #"(-?\d+)d"#, in: input) }
    private func weeks(_ input: String) -> Int { firstNumber(matching: #"(-?\d+)w"#, in: input) }
    private func months(_ input: String) -> Int { firstNumber(matching: #"(-?\d+)m"#, in: input) }
    private func years(_ input: String) -> Int { firstNumber(matching: #"(-?\d+)y"#, in: input) }
    private func weekNumber(_ input: String) -> Int { firstNumber(matching: #"w(\d+)"#, in: input) }
    private func dayNumber(_ input: String) -> Int { firstNumber(matching: #"d(\d+)"#, in: input) }
    private func businessDays5(_ input: String) -> Int { firstNumber(matching: #"(-?\d+)b5"#, in: input) }
    private func businessDays6(_ input: String) -> Int { firstNumber(matching: #"(-?\d+)b6"#, in: input) }

    private func isTodayShortcut(_ input: String) -> Bool {
        input.range(of: "t", options: .caseInsensitive) != nil
    }

    // MARK: - Public

    /// Tries to read `string` as a date in the user's short date style (or "t" for today).
    func parseDate(_ string: String) -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .short

        if let date = formatter.date(from: string) {
            calendar?.setDate(date)
            return true
        }
        if isTodayShortcut(string) {
            calendar?.setDate(Date())
            return true
        }
        return false
    }

    /// Moves the calendar by the relative expression in `string`.
    func moveDate(_ string: String, useToday: Bool) {
        guard let calendar else { return }
        let startDate = useToday ? Date() : calendar.selectedDate
        let current = Calendar.current

        if case let units = days(string), units != 0 {
            calendar.setDate(add(to: startDate.noonOfDay, unit: .day, count: units))
        } else if case let units = weeks(string), units != 0 {
            calendar.setDate(add(to: startDate.noonOfDay, unit: .week, count: units))
        } else if case let units = months(string), units != 0 {
            calendar.setDate(add(to: startDate.noonOfDay, unit: .month, count: units))
        } else if case let units = years(string), units != 0 {
            calendar.setDate(add(to: startDate.noonOfDay, unit: .year, count: units))
        } else if case let units = weekNumber(string), units != 0 {
            // week number, counted from the start of the selected year
            if units < 54 {
                var components = DateComponents()
                components.yearForWeekOfYear = current.component(.year, from: startDate)
                components.weekOfYear = units
                components.weekday = 1
                if let date = current.date(from: components) {
                    calendar.setDate(date)
                }
            }
        } else if case let units = dayNumber(string), units != 0 {
            // day of the year
            if units < 366 {
                var components = DateComponents()
                components.year = current.component(.year, from: startDate)
                components.month = 1
                components.day = 1
                if let firstOfYear = current.date(from: components) {
                    calendar.setDate(add(to: firstOfYear.noonOfDay, unit: .day, count: units - 1))
                }
            }
        } else if case let units = businessDays5(string), units != 0 {
            calendar.setDate(addBusinessDays(to: startDate, days: units, fullWeek: true))
        } else if case let units = businessDays6(string), units != 0 {
            calendar.setDate(addBusinessDays(to: startDate, days: units, fullWeek: false))
        }
    }
}
