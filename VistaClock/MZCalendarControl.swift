//
//  MZCalendarControl.swift
//  VistaClock
//
//  Created by Paul Wong on 9/5/14.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

import AppKit
import EventKit

/// A month calendar drawn by hand, with optional week numbers, boxes and
/// indicators for days that have events or reminders.
final class MZCalendarControl: NSControl {
    private static let offsetH: CGFloat = 4
    private static let offsetV: CGFloat = 6
    private static let indicatorXOffset: CGFloat = 6
    private static let indicatorYOffset: CGFloat = 5
    private static let numberOfRows = 8
    private static let monthViewDays = 42

    /// The selected day (always local noon).
    private(set) var selectedDate = Date().noonOfDay

    /// The 42 days shown, starting with the leading days of the previous month.
    private var monthView: [Date] = []
    private var firstDay = 0
    private var lastDay = 0

    // user controlled, off by default
    var showWeekNumbers = false { didSet { if showWeekNumbers != oldValue { needsDisplay = true } } }
    var showBoxes = false { didSet { if showBoxes != oldValue { needsDisplay = true } } }
    var useShadow = false { didSet { if useShadow != oldValue { updateStyle() } } }

    var showEventIndicators = false {
        didSet {
            if showEventIndicators != oldValue {
                refreshIndicators()
            }
        }
    }

    var showReminderIndicators = false {
        didSet {
            if showReminderIndicators != oldValue {
                refreshIndicators()
            }
        }
    }

    var fontSize: CGFloat = 13 {
        didSet { if fontSize != oldValue { updateStyle() } }
    }

    var hiliteColor: NSColor = .controlAccentColor {
        didSet { updateStyle() }
    }

    // layout, recomputed on every draw
    private var dayWidth = 0
    private var dayHeight = 0
    private var columnCount = 7
    private var weekColumnOffset = 0

    private var attributes = Attributes()

    // calendar store
    private let store = EKEventStore()
    private var daysWithEvents: Set<Date> = []
    private var daysWithReminders: Set<Date> = []
    private var reminderFetchID = 0

    private struct Attributes {
        var title: [NSAttributedString.Key: Any] = [:]
        var normal: [NSAttributedString.Key: Any] = [:]
        var daysNotThisMonth: [NSAttributedString.Key: Any] = [:]
        var dayOfWeek: [NSAttributedString.Key: Any] = [:]
        var currentDay: [NSAttributedString.Key: Any] = [:]
        var week: [NSAttributedString.Key: Any] = [:]
    }

    // MARK: - Setup

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        setDate(Date())
        updateStyle()

        NotificationCenter.default.addObserver(
            self, selector: #selector(storeChanged(_:)), name: .EKEventStoreChanged, object: nil)
    }

    @objc private func storeChanged(_ notification: Notification) {
        refreshIndicators()
    }

    // MARK: - Date

    /// Selects the day containing `date` and rebuilds the visible month.
    func setDate(_ date: Date) {
        let calendar = Calendar.current
        selectedDate = date.noonOfDay

        let year = selectedDate.year
        let month = selectedDate.month
        let firstOfMonth = Date.noon(year: year, month: month, day: 1)
        let numberOfDays = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30

        // leave some days of the previous month first (1 to 7 of them)
        var leadingDays = firstOfMonth.usDayOfWeek - calendar.firstWeekday
        if leadingDays == 0 {
            leadingDays = 7
        } else if leadingDays < 0 {
            leadingDays += 7
        }

        let start = calendar.date(byAdding: .day, value: -leadingDays, to: firstOfMonth) ?? firstOfMonth
        monthView = (0..<Self.monthViewDays).map {
            calendar.date(byAdding: .day, value: $0, to: start) ?? start
        }
        firstDay = leadingDays
        lastDay = leadingDays + numberOfDays - 1

        refreshIndicators()
        needsDisplay = true
    }

    func nextMonth() {
        setDate(Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate)
    }

    func lastMonth() {
        setDate(Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate)
    }

    // MARK: - Style

    private func updateStyle() {
        let shadow = NSShadow()
        shadow.shadowColor = useShadow ? NSColor.shadowColor : nil
        shadow.shadowOffset = NSSize(width: 1, height: -1)
        shadow.shadowBlurRadius = 1.5

        func make(_ font: NSFont, _ color: NSColor) -> [NSAttributedString.Key: Any] {
            [.font: font, .foregroundColor: color, .shadow: shadow]
        }

        let dayFont = NSFont.systemFont(ofSize: fontSize)
        attributes.dayOfWeek = make(.systemFont(ofSize: fontSize - 3), .textColor)
        attributes.title = make(.systemFont(ofSize: fontSize + 2), .textColor)
        attributes.week = make(.systemFont(ofSize: fontSize - 4), .systemGray)
        attributes.daysNotThisMonth = make(dayFont, .systemGray)
        attributes.currentDay = make(dayFont, .selectedMenuItemTextColor)
        attributes.normal = make(dayFont, .textColor)

        needsDisplay = true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateStyle()
    }

    // MARK: - Events and reminders

    /// Reloads which visible days have events or reminders.
    func refreshIndicators() {
        guard let first = monthView.first, let last = monthView.last else { return }
        let calendar = Calendar.current
        let rangeStart = calendar.startOfDay(for: first)
        let rangeEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: last)) ?? last

        if showEventIndicators {
            daysWithEvents = Self.days(of: store.events(matching:
                store.predicateForEvents(withStart: rangeStart, end: rangeEnd, calendars: nil)))
        } else {
            daysWithEvents = []
        }

        reminderFetchID += 1
        if showReminderIndicators {
            let fetchID = reminderFetchID
            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: rangeStart, ending: rangeEnd, calendars: nil)
            store.fetchReminders(matching: predicate) { [weak self] reminders in
                // Reduce to plain dates before leaving the completion queue.
                let days = Set((reminders ?? []).compactMap { reminder -> Date? in
                    guard let due = reminder.dueDateComponents,
                          let date = Calendar.current.date(from: due) else { return nil }
                    return Calendar.current.startOfDay(for: date)
                })
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        guard let self, fetchID == self.reminderFetchID else { return }
                        self.daysWithReminders = days
                        self.needsDisplay = true
                    }
                }
            }
        } else {
            daysWithReminders = []
        }
        needsDisplay = true
    }

    private static func days(of events: [EKEvent]) -> Set<Date> {
        let calendar = Calendar.current
        var days = Set<Date>()
        for event in events {
            guard let start = event.startDate, let end = event.endDate else { continue }
            // every day from the start up to (not including) the end; an event
            // ending exactly at midnight does not touch the next day
            var day = calendar.startOfDay(for: start)
            repeat {
                days.insert(day)
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            } while day < end
        }
        return days
    }

    private func hasEvents(on date: Date) -> Bool {
        daysWithEvents.contains(Calendar.current.startOfDay(for: date))
    }

    private func hasReminders(on date: Date) -> Bool {
        daysWithReminders.contains(Calendar.current.startOfDay(for: date))
    }

    // MARK: - Hit testing

    /// The date under `point`, or nil when the point is in the header.
    func date(at point: NSPoint) -> Date? {
        guard dayWidth > 0, dayHeight > 0, !monthView.isEmpty else { return nil }

        if point.y > bounds.height - Self.offsetV - CGFloat(dayHeight) {
            return nil // it's a control
        }

        var row = Int((bounds.height - point.y - Self.offsetV - CGFloat(dayHeight * 2)) / CGFloat(dayHeight))
        var column = Int((point.x - Self.offsetH - CGFloat(weekColumnOffset)) / CGFloat(dayWidth))
        column = min(max(column, 0), 6)
        row = min(max(row, 0), 5)
        return monthView[row * 7 + column]
    }

    /// -1 for previous month, 1 for next month, 0 for today.
    private func control(at point: NSPoint) -> Int {
        let offset = Self.offsetH + CGFloat(weekColumnOffset)
        if point.x > offset + CGFloat(6 * dayWidth) {
            return 1
        } else if point.x > offset + CGFloat(5 * dayWidth) {
            return 0
        } else if point.x > offset + CGFloat(4 * dayWidth) {
            return -1
        }
        return 0
    }

    // MARK: - Drawing

    private func drawBox(_ rect: NSRect, rounded: Bool, color: NSColor, lineWidth: CGFloat) {
        let path = rounded
            ? NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
            : NSBezierPath(rect: rect)
        path.lineWidth = lineWidth
        path.lineJoinStyle = .round
        color.set()
        path.stroke()
    }

    private func drawCentered(_ string: String, in rect: NSRect, attributes: [NSAttributedString.Key: Any], yOffset: CGFloat) {
        let size = string.size(withAttributes: attributes)
        string.draw(at: NSPoint(x: rect.midX - size.width * 0.5, y: rect.minY + yOffset), withAttributes: attributes)
    }

    private func headerRect(column: Int) -> NSRect {
        NSRect(x: Self.offsetH + CGFloat(column * dayWidth + weekColumnOffset),
               y: bounds.height - CGFloat(dayHeight) - Self.offsetV,
               width: CGFloat(dayWidth - 1), height: CGFloat(dayHeight - 1))
    }

    private func drawDay(_ index: Int) {
        let row = index / 7
        let column = index - row * 7
        let date = monthView[index]
        let string = date.dayString

        let rect = NSRect(
            x: Self.offsetH + CGFloat(dayWidth * column + weekColumnOffset),
            y: bounds.height - CGFloat(row + 3) * CGFloat(dayHeight) - Self.offsetV,
            width: CGFloat(dayWidth - 1), height: CGFloat(dayHeight - 1))

        let isToday = Calendar.current.isDateInToday(date)
        let inMonth = index >= firstDay && index <= lastDay

        if isToday {
            let path = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
            path.lineJoinStyle = .round
            hiliteColor.set()
            path.fill()
            if showBoxes && inMonth {
                drawBox(rect, rounded: true, color: .textColor, lineWidth: 1)
            }
            drawCentered(string, in: rect, attributes: attributes.currentDay, yOffset: 3)
        } else if !inMonth {
            drawCentered(string, in: rect, attributes: attributes.daysNotThisMonth, yOffset: 3)
        } else {
            if showBoxes {
                drawBox(rect, rounded: true, color: .textColor, lineWidth: 1)
            }
            drawCentered(string, in: rect, attributes: attributes.normal, yOffset: 3)
        }

        // selected date
        if inMonth && Calendar.current.isDate(date, inSameDayAs: selectedDate) {
            drawBox(rect.insetBy(dx: 1, dy: 1), rounded: true, color: hiliteColor, lineWidth: 2)
        }

        // event indicator (grey on the highlighted current day)
        if showEventIndicators && hasEvents(on: date) {
            let image = NSImage(named: isToday ? "tiny_grey_on" : "tiny_blue_on")
            image?.draw(at: NSPoint(x: rect.maxX - Self.indicatorXOffset, y: rect.midY - Self.indicatorYOffset),
                        from: .zero, operation: .sourceOver, fraction: 1.0)
        }

        // reminder indicator
        if showReminderIndicators && hasReminders(on: date) {
            NSImage(named: "tiny_red_on")?.draw(
                at: NSPoint(x: rect.maxX - Self.indicatorXOffset, y: rect.midY),
                from: .zero, operation: .sourceOver, fraction: 1.0)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard monthView.count == Self.monthViewDays else { return }

        columnCount = showWeekNumbers ? 8 : 7
        dayWidth = Int((bounds.width - 2 * Self.offsetH) / CGFloat(columnCount))
        dayHeight = Int((bounds.height - 2 * Self.offsetV) / CGFloat(Self.numberOfRows))
        weekColumnOffset = showWeekNumbers ? dayWidth : 0

        // month + year
        let titleRect = NSRect(
            x: Self.offsetH, y: bounds.height - CGFloat(dayHeight) - Self.offsetV,
            width: CGFloat(dayWidth * (columnCount - 3) - 1), height: CGFloat(dayHeight - 1))
        selectedDate.monthYearString.draw(
            at: NSPoint(x: titleRect.minX + Self.offsetH, y: titleRect.minY + 2),
            withAttributes: attributes.title)

        // previous month, today and next month controls
        for (offset, symbol) in [(4, "⇠"), (5, "•"), (6, "⇢")] {
            drawCentered(symbol, in: headerRect(column: offset), attributes: attributes.title, yOffset: 2)
        }

        // week header
        for column in 0..<7 {
            let rect = NSRect(
                x: Self.offsetH + CGFloat(column * dayWidth + weekColumnOffset),
                y: bounds.height - CGFloat(dayHeight * 2) - Self.offsetV,
                width: CGFloat(dayWidth - 1), height: CGFloat(dayHeight - 1))
            drawCentered(monthView[column].dayNameShortString, in: rect, attributes: attributes.dayOfWeek, yOffset: 3)
        }

        for index in 0..<Self.monthViewDays {
            drawDay(index)
        }

        // week numbers
        if showWeekNumbers {
            let useISO = Calendar.userCalendarIdentifier == .iso8601
            for row in 1..<8 {
                let rect = NSRect(
                    x: Self.offsetH, y: bounds.height - CGFloat(row + 1) * CGFloat(dayHeight) - Self.offsetV,
                    width: CGFloat(dayWidth - 1), height: CGFloat(dayHeight - 1))
                let string: String
                if row == 1 {
                    string = "cw"
                } else {
                    let date = monthView[(row - 2) * 7]
                    string = useISO ? date.isoWeekNumberString : date.weekNumberString
                }
                string.draw(at: NSPoint(x: rect.minX + Self.offsetH, y: rect.minY + 4.5),
                            withAttributes: attributes.week)
            }
        }
    }

    // MARK: - Mouse

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        guard let day = date(at: point) else {
            // not a date so check the controls
            switch control(at: point) {
            case -1: lastMonth()
            case 1: nextMonth()
            default: setDate(Date())
            }
            return
        }

        guard !Calendar.current.isDate(day, inSameDayAs: selectedDate) else { return }
        if selectedDate.month != day.month {
            setDate(day)
        } else {
            selectedDate = day
            needsDisplay = true
        }
    }

    /// Right-click opens Calendar; control-right-click opens Reminders.
    override func rightMouseDown(with event: NSEvent) {
        let bundleIdentifier = event.modifierFlags.contains(.control) ? "com.apple.reminders" : "com.apple.iCal"
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else { return }
        NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            if let error {
                NSLog("Failed to open application at %@: %@", appURL.path, String(describing: error))
            }
        }
    }
}
