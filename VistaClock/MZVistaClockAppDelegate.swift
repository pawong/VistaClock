//
//  MZVistaClockAppDelegate.swift
//  VistaClock
//
//  Created by Paul Wong on 9/5/14.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

import AppKit
import EventKit

private extension NSToolbarItem.Identifier {
    static let title = NSToolbarItem.Identifier("TitleID")
    static let dateBox = NSToolbarItem.Identifier("DateBoxID")
    static let gotoToday = NSToolbarItem.Identifier("GotoTodayID")
    static let dateDetails = NSToolbarItem.Identifier("DateDetailsID")
    static let settings = NSToolbarItem.Identifier("SettingsID")
}

@main
@MainActor
final class MZVistaClockAppDelegate: NSObject, NSApplicationDelegate, NSToolbarDelegate {
    // date formats
    private static let timezoneDayFormat = "z ccc"
    private static let timeFormatNormal = "h:mm a"
    private static let timeFormatNormalFull = "h:mm:ss a"
    private static let timeFormatMilitary = "HH:mm"

    // window sizes
    private static let calendarWidth: CGFloat = 290
    private static let contentHeight: CGFloat = 230
    private static let clockWidth: CGFloat = 146
    private static let clockHeight: CGFloat = 214

    private let settings = VCSettings.shared

    // status item
    private var statusItem: NSStatusItem?
    private let statusMenu = NSMenu()
    private let timeNowMenuItem = NSMenuItem(title: "TimeNow", action: nil, keyEquivalent: "")

    // main window
    private let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 452, height: MZVistaClockAppDelegate.contentHeight),
        styleMask: [.titled], backing: .buffered, defer: true)
    private let calendarControl = MZCalendarControl()
    private let altCalendarContainer = NSView()
    private let altCalendar = NSDatePicker()
    private let clockScroll = NSScrollView()
    private let clockStack = NSStackView()
    private var clockScrollWidth: NSLayoutConstraint?
    private var clockItems: [MZClockItem] = []
    private var hasPositionedWindow = false

    // toolbar
    private let toolbar = NSToolbar(identifier: "VistaClockToolbar")
    private var toolbarItems: [NSToolbarItem.Identifier: NSToolbarItem] = [:]
    private let titleLabel = NSTextField(labelWithString: "")
    private let dayDetailLabel = NSTextField(labelWithString: "")
    private let gotoDateField = MZTextField()
    private let toolbarMenuItem = NSMenuItem(title: "Show Toolbar", action: nil, keyEquivalent: "t")
    private let autoHideMenuItem = NSMenuItem(title: "Pin to Desktop", action: nil, keyEquivalent: "p")
    private var showToolbar = false

    // secondary windows
    private var prefsWindow: MZVistaClockPreferences?
    private var aboutBox: MZAboutBox?

    // misc state
    private var timer: Timer?
    private var statusItemFormat = ""
    private var lastWeek = -1
    private var lastDate = Date().noonOfDay
    private var lastCalendarIdentifier: Calendar.Identifier?
    private var darkMenu = false

    // MARK: - Entry point

    static func main() {
        // AppKit objects (the delegate owns a window) must not exist before NSApplication
        let app = NSApplication.shared
        let delegate = MZVistaClockAppDelegate()
        app.delegate = delegate
        app.run()
    }

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        processCommandLine()

        if settings.showDockIcon {
            NSApp.setActivationPolicy(.regular)
        }

        buildWindow()
        buildMenus()
        requestCalendarAccess()

        // set the date box place holder to the locale's short date format
        let dateFormat = DateFormatter()
        dateFormat.locale = Locale(identifier: Locale.preferredLanguages.first ?? "en_US")
        dateFormat.dateStyle = .short
        gotoDateField.placeholderString = dateFormat.dateFormat

        configureToolbar(full: false)
        createStatusItem()

        // should be true, but make sure
        settings.needsDisplay = true
        updateTime()

        // fires while menus are open too
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateTime() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// `-R` resets the settings; `-F:1` / `-F:0` set the float-right flag.
    private func processCommandLine() {
        let arguments = CommandLine.arguments

        // reset takes priority
        if arguments.contains("-R") {
            settings.reset()
            settings.archive()
        }
        for argument in arguments {
            if argument == "-F:1" {
                settings.floatRight = true
                settings.archive()
            } else if argument == "-F:0" {
                settings.floatRight = false
                settings.archive()
            }
        }
    }

    // MARK: - Window

    private func buildWindow() {
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.toolbarStyle = .expanded
        window.collectionBehavior = .moveToActiveSpace

        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar

        // calendar, or a system date picker for calendars we can't draw ourselves
        calendarControl.translatesAutoresizingMaskIntoConstraints = false

        altCalendar.datePickerStyle = .clockAndCalendar
        altCalendar.datePickerElements = [.yearMonthDay, .hourMinuteSecond]
        altCalendar.translatesAutoresizingMaskIntoConstraints = false
        altCalendarContainer.translatesAutoresizingMaskIntoConstraints = false
        altCalendarContainer.addSubview(altCalendar)
        altCalendarContainer.isHidden = true

        // clocks
        clockStack.orientation = .horizontal
        clockStack.alignment = .top
        clockStack.spacing = 0
        clockStack.translatesAutoresizingMaskIntoConstraints = false

        clockScroll.documentView = clockStack
        clockScroll.drawsBackground = false
        clockScroll.borderType = .noBorder
        clockScroll.hasVerticalScroller = false
        clockScroll.hasHorizontalScroller = false
        clockScroll.horizontalScrollElasticity = .automatic
        clockScroll.verticalScrollElasticity = .none
        clockScroll.translatesAutoresizingMaskIntoConstraints = false

        let scrollWidth = clockScroll.widthAnchor.constraint(equalToConstant: 0)
        clockScrollWidth = scrollWidth

        let clipView = clockScroll.contentView
        NSLayoutConstraint.activate([
            calendarControl.widthAnchor.constraint(equalToConstant: Self.calendarWidth),
            calendarControl.heightAnchor.constraint(equalToConstant: Self.clockHeight),
            altCalendarContainer.widthAnchor.constraint(equalToConstant: Self.calendarWidth),
            altCalendarContainer.heightAnchor.constraint(equalToConstant: Self.clockHeight),
            altCalendar.centerXAnchor.constraint(equalTo: altCalendarContainer.centerXAnchor),
            altCalendar.centerYAnchor.constraint(equalTo: altCalendarContainer.centerYAnchor),
            scrollWidth,
            clockScroll.heightAnchor.constraint(equalToConstant: Self.clockHeight),
            clockStack.topAnchor.constraint(equalTo: clipView.topAnchor),
            clockStack.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            clockStack.heightAnchor.constraint(equalTo: clipView.heightAnchor),
        ])

        let content = NSStackView(views: [calendarControl, altCalendarContainer, clockScroll])
        content.orientation = .horizontal
        content.alignment = .top
        content.spacing = 0
        content.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        window.contentView = content

        // toolbar fields
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.lineBreakMode = .byClipping
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 104),
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
        ])

        dayDetailLabel.lineBreakMode = .byClipping
        dayDetailLabel.translatesAutoresizingMaskIntoConstraints = false
        dayDetailLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 90).isActive = true

        gotoDateField.target = self
        gotoDateField.action = #selector(gotoDate(_:))
        gotoDateField.isBezeled = true
        gotoDateField.bezelStyle = .roundedBezel
        gotoDateField.focusRingType = .none
        gotoDateField.translatesAutoresizingMaskIntoConstraints = false
        gotoDateField.widthAnchor.constraint(equalToConstant: 110).isActive = true
        gotoDateField.onCancel = { [weak self] in
            MainActor.assumeIsolated { self?.toggleVistaClockWindow(nil) }
        }
    }

    /// Sizes the window to fit the calendar and as many clocks as the screen allows.
    private func resizeWindow() {
        let clocksOnly = !settings.showCalendar && !settings.clockConfigs.isEmpty
        let calendarVisible = !clocksOnly
        let gregorianStyle = Calendar.userCalendarIsGregorianStyle

        window.titleVisibility = showToolbar ? .visible : .hidden

        calendarControl.isHidden = !(calendarVisible && gregorianStyle)
        altCalendarContainer.isHidden = !(calendarVisible && !gregorianStyle)

        var windowWidth: CGFloat = clocksOnly ? 16 : Self.calendarWidth + 16
        let maxWidth = NSScreen.main?.visibleFrame.width ?? 1440
        var clocksWidth: CGFloat = 0
        for _ in settings.clockConfigs {
            if clocksWidth + Self.clockWidth + windowWidth > maxWidth { break }
            clocksWidth += Self.clockWidth
        }
        windowWidth += clocksWidth

        clockScrollWidth?.constant = clocksWidth
        clockScroll.isHidden = clocksWidth == 0

        // keep the top-left corner where it is
        var frame = window.frameRect(forContentRect: NSRect(x: 0, y: 0, width: windowWidth, height: Self.contentHeight))
        frame.origin = NSPoint(x: window.frame.minX, y: window.frame.maxY - frame.height)
        window.setFrame(frame, display: true, animate: window.isVisible)
    }

    private func positionWindowBelowStatusItem() {
        guard !hasPositionedWindow, let buttonFrame = statusItem?.button?.window?.frame else { return }
        hasPositionedWindow = true

        let visible = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let x = min(max(buttonFrame.maxX - window.frame.width, visible.minX), visible.maxX - window.frame.width)
        window.setFrameTopLeftPoint(NSPoint(x: x, y: buttonFrame.minY - 4))
    }

    /// Opens or closes the clock window.
    @IBAction func toggleVistaClockWindow(_ sender: Any?) {
        if window.isVisible && NSApp.isActive {
            window.orderOut(self)
        } else {
            positionWindowBelowStatusItem()
            bringForward(window)
        }
        window.collectionBehavior = .moveToActiveSpace
    }

    /// Shows `window` in front of every other app's windows.
    ///
    /// Activating an accessory (menu bar only) app is not always granted, and a window of an
    /// inactive app opens behind the others, so the window is also ordered front explicitly.
    private func bringForward(_ window: NSWindow?) {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }

    @objc func cancelOperation(_ sender: Any?) {
        toggleVistaClockWindow(nil)
    }

    // MARK: - Menus

    private func buildMenus() {
        // right-click menu on the status item
        timeNowMenuItem.isEnabled = false
        statusMenu.autoenablesItems = false
        statusMenu.addItem(timeNowMenuItem)
        statusMenu.addItem(.separator())
        statusMenu.addItem(item("About", #selector(launchAboutBoxPanel(_:))))
        statusMenu.addItem(item("Preferences...", #selector(openPreferences(_:))))
        statusMenu.addItem(item("Date & Time Preferences...", #selector(launchDateTimePreferencePanel(_:))))
        statusMenu.addItem(.separator())
        statusMenu.addItem(item("Quit", #selector(NSApplication.terminate(_:)), key: "q", target: NSApp))
    }

    private func item(_ title: String, _ action: Selector, key: String = "", target: AnyObject? = nil) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
        menuItem.target = target ?? self
        return menuItem
    }

    /// The gear menu in the window toolbar.
    private func makeSettingsMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        toolbarMenuItem.action = #selector(toggleToolbar(_:))
        toolbarMenuItem.target = self
        toolbarMenuItem.isEnabled = false
        autoHideMenuItem.action = #selector(toggleAutoHide(_:))
        autoHideMenuItem.target = self

        menu.addItem(toolbarMenuItem)
        menu.addItem(autoHideMenuItem)
        menu.addItem(.separator())
        menu.addItem(item("Launch Calendar", #selector(launchCalendar(_:)), key: "d"))
        menu.addItem(item("Launch Reminders", #selector(launchReminders(_:)), key: "r"))
        menu.addItem(.separator())
        menu.addItem(item("Preferences...", #selector(openPreferences(_:))))
        menu.addItem(item("Date & Time Preferences...", #selector(launchDateTimePreferencePanel(_:))))
        menu.addItem(item("Help...", #selector(launchHelpPanel(_:))))
        menu.addItem(.separator())
        menu.addItem(item("Quit", #selector(NSApplication.terminate(_:)), key: "q", target: NSApp))
        return menu
    }

    // MARK: - Toolbar

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.title, .dateBox, .gotoToday, .dateDetails, .flexibleSpace, .settings]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.title, .flexibleSpace, .settings]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if let cached = toolbarItems[itemIdentifier] {
            return cached
        }

        let toolbarItem: NSToolbarItem
        switch itemIdentifier {
        case .title:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.label = "Title"
            toolbarItem.view = titleLabel
        case .dateBox:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.label = "Go to Date"
            toolbarItem.view = gotoDateField
        case .gotoToday:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.label = "Today"
            toolbarItem.toolTip = "Go to Today"
            toolbarItem.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Go to Today")
            toolbarItem.isBordered = true
            toolbarItem.target = self
            toolbarItem.action = #selector(goToday(_:))
        case .dateDetails:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.label = "Date Details"
            toolbarItem.toolTip = "Day of the year / days from today"
            toolbarItem.view = dayDetailLabel
        case .settings:
            let menuItem = NSMenuToolbarItem(itemIdentifier: itemIdentifier)
            menuItem.label = "Settings"
            menuItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings")
            menuItem.menu = makeSettingsMenu()
            menuItem.showsIndicator = false
            toolbarItem = menuItem
        default:
            return nil
        }

        toolbarItems[itemIdentifier] = toolbarItem
        return toolbarItem
    }

    /// Shows either the title (compact) or the date tools (full) next to the gear menu.
    private func configureToolbar(full: Bool) {
        while !toolbar.items.isEmpty {
            toolbar.removeItem(at: 0)
        }

        var identifiers: [NSToolbarItem.Identifier] = full ? [.dateBox, .gotoToday, .dateDetails] : [.title]
        identifiers += [.flexibleSpace, .settings]
        for (index, identifier) in identifiers.enumerated() {
            toolbar.insertItem(withItemIdentifier: identifier, at: index)
        }

        resizeWindow()

        // The toolbar installs the field's view a moment later; focus it only once it is in the window.
        DispatchQueue.main.async { [self] in
            window.makeFirstResponder(full && gotoDateField.window === window ? gotoDateField : nil)
        }
    }

    @IBAction func toggleToolbar(_ sender: Any?) {
        showToolbar.toggle()
        toolbarMenuItem.title = showToolbar ? "Hide Toolbar" : "Show Toolbar"
        configureToolbar(full: showToolbar)
    }

    @IBAction func toggleAutoHide(_ sender: Any?) {
        settings.useAutoHide.toggle()
        window.hidesOnDeactivate = settings.useAutoHide
        updateAutoHideMenuItem()
    }

    private func updateAutoHideMenuItem() {
        autoHideMenuItem.title = settings.useAutoHide ? "Pin to Desktop" : "Unpin from Desktop"
        prefsWindow?.updateWindowControls()
    }

    // MARK: - Go to date

    @IBAction func gotoDate(_ sender: Any?) {
        let calc = MZDateCalc()
        calc.calendar = calendarControl

        let strings = gotoDateField.stringValue.components(separatedBy: ",")
        if strings.count > 1 {
            // "<date>, <move>": jump to the date if there is one, then move from there
            _ = calc.parseDate(strings[0])
            calc.moveDate(strings[1], useToday: false)
        } else if !calc.parseDate(strings[0]) {
            calc.moveDate(strings[0], useToday: true)
        }
    }

    @IBAction func goToday(_ sender: Any?) {
        gotoDateField.stringValue = ""
        calendarControl.setDate(Date())
    }

    // MARK: - Status item

    private func createStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "VistaClockStatusItem"
        statusItem = item

        guard let button = item.button else { return }
        button.target = self
        button.action = #selector(statusItemButtonClicked(_:))
        button.imagePosition = .imageLeading
        // handle right-click ourselves rather than through statusItem.menu
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemButtonClicked(_ sender: Any?) {
        guard let button = statusItem?.button else { return }
        // right-click (or control-click) opens the menu; anything else toggles the window
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            statusMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
        } else {
            toggleVistaClockWindow(sender)
        }
    }

    private var isDarkMenu: Bool {
        statusItem?.button?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    /// The date part of the status item title, built from the user's settings.
    private func buildStatusItemDateFormatString() -> String {
        var format = ""

        if settings.showStatusWeekDay && settings.showDate {
            format += "EEE"
        }

        if settings.showDate {
            let longFormat = DateFormatter()
            longFormat.locale = Locale(identifier: Locale.preferredLanguages.first ?? "en_US")
            longFormat.dateStyle = .long
            var dateFormat = longFormat.dateFormat ?? ""
            dateFormat = dateFormat.replacingOccurrences(of: "y", with: "")
            dateFormat = dateFormat.replacingOccurrences(of: ",", with: "")
            if !settings.showMonth {
                dateFormat = dateFormat.replacingOccurrences(of: "MMMM", with: "")
            } else if !settings.showStatusFullMonth {
                dateFormat = dateFormat.replacingOccurrences(of: "MMMM", with: "MMM")
            }
            format += " " + dateFormat
        }

        if settings.showTime {
            var time = settings.useStatusMilitary ? " HH:mm" : " h:mm"
            if settings.showStatusSeconds {
                time += ":ss"
            }
            if !settings.useStatusMilitary && settings.showStatusAMPM {
                time += " a"
            }
            format += time
        }

        return format.trimmingCharacters(in: .whitespaces)
    }

    /// The menu bar icon showing the current week number on a calendar page.
    private func weekNumberImage(_ weekString: String, weekNumber: Int) -> NSImage? {
        guard let base = NSImage(named: settings.useBWWeekIcon ? "bw_calendar" : "c_calendar") else { return nil }
        let origin = NSPoint(x: weekNumber < 10 ? 8 : 4, y: 1)
        let blackAndWhite = settings.useBWWeekIcon

        return NSImage(size: base.size, flipped: false) { rect in
            base.draw(in: rect)
            // black and white icons follow the menu bar's appearance
            var attributes: [NSAttributedString.Key: Any] = [:]
            if blackAndWhite, NSAppearance.currentDrawing().bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                attributes[.foregroundColor] = NSColor.white
            }
            weekString.draw(at: origin, withAttributes: attributes)
            return true
        }
    }

    private func updateStatusItemImage(now: Date) {
        guard let button = statusItem?.button else { return }

        if settings.showWeekNumberIcon {
            let isISO = Calendar.userCalendarIdentifier == .iso8601
            let weekString = isISO ? now.isoWeekNumberString : now.weekNumberString
            let thisWeek = isISO ? now.isoWeekNumber : now.weekNumber
            if lastWeek != thisWeek {
                button.image = weekNumberImage(weekString, weekNumber: thisWeek)
                lastWeek = thisWeek
            }
        } else if settings.showDateTime && (settings.showTime || settings.showDate) {
            button.image = nil // the title is enough
        } else {
            let family = settings.useBWIcon ? "bw" : "c"
            button.image = NSImage(named: "\(family)_\(isDarkMenu ? "w" : "b")_mazookie")
        }
    }

    // MARK: - Updating

    /// Called every second.
    private func updateTime() {
        if settings.needsDisplay {
            configureWindow()
        }

        // switch icons with the menu bar appearance
        if isDarkMenu != darkMenu {
            lastWeek = -1 // force redraw
            darkMenu = isDarkMenu
        }

        let now = Date()
        let locale = Locale(identifier: Locale.preferredLanguages.first ?? "en_US")
        let formatter = DateFormatter()
        formatter.locale = locale

        formatter.dateFormat = statusItemFormat
        let statusItemDate = formatter.string(from: now)

        formatter.dateFormat = nil
        formatter.dateStyle = .full
        let fullDate = formatter.string(from: now)
        formatter.timeStyle = .long
        let fullDateTime = formatter.string(from: now)
        formatter.timeStyle = .none
        formatter.dateStyle = .medium
        let mediumDate = formatter.string(from: now)
        formatter.dateStyle = .short
        let shortDate = formatter.string(from: now)
        formatter.dateStyle = .none
        formatter.dateFormat = Self.timeFormatNormalFull
        let normalFullTime = formatter.string(from: now)

        // update the status item
        updateStatusItemImage(now: now)
        applyStatusItemTitle(statusItemTitle(now: now, statusItemDate: statusItemDate, locale: locale))

        // menu item
        timeNowMenuItem.title = fullDateTime

        // window title
        if clockItems.isEmpty {
            window.title = showToolbar ? normalFullTime : ""
            titleLabel.stringValue = normalFullTime
        } else {
            window.title = showToolbar ? fullDate : ""
            let width = window.frame.width
            titleLabel.stringValue = width > 288 ? fullDate : (width > 150 ? mediumDate : shortDate)
        }

        // clocks
        for (index, clockItem) in clockItems.enumerated() {
            clockItem.update(now)
            if index == 0 && settings.showDockIcon, let image = clockItem.image {
                NSApp.applicationIconImage = image
            }
        }

        // calendar: switch between our control and the system date picker when the user's calendar changes
        if isCalendarChanged() && (settings.showCalendar || settings.clockConfigs.isEmpty) {
            if Calendar.userCalendarIsGregorianStyle {
                calendarControl.isHidden = false
                altCalendarContainer.isHidden = true
                calendarControl.setDate(calendarControl.selectedDate)
                toolbarMenuItem.isEnabled = true
            } else {
                altCalendarContainer.isHidden = false
                calendarControl.isHidden = true
                altCalendar.dateValue = now
                // the toolbar is only enabled if the gregorian calendar is showing
                if showToolbar {
                    toggleToolbar(self)
                }
                toolbarMenuItem.isEnabled = false
            }
        }

        // move to the current date when the day changes
        if !Calendar.current.isDate(lastDate, inSameDayAs: now) {
            lastDate = now.noonOfDay
            calendarControl.setDate(lastDate)
        }

        // day details
        if window.isVisible && showToolbar {
            let selected = calendarControl.selectedDate
            let days = Int(selected.timeIntervalSince(now.noonOfDay)) / 86400
            dayDetailLabel.stringValue = "\(selected.dayOfYearString) / \(days)"
        }
    }

    /// Sets the status item text. With "Use Inverse Color" it is black on a white rounded
    /// background, whatever the menu bar looks like; otherwise it follows the menu bar.
    private func applyStatusItemTitle(_ title: String) {
        guard let button = statusItem?.button else { return }

        let inverse = settings.useInverseTitle && !title.isEmpty
        button.wantsLayer = true
        button.layer?.cornerRadius = 4
        button.layer?.backgroundColor = inverse ? NSColor.white.cgColor : nil

        if inverse {
            button.attributedTitle = NSAttributedString(string: title, attributes: [
                .foregroundColor: NSColor.black,
                .font: NSFont.menuBarFont(ofSize: 0),
            ])
        } else {
            button.title = title // plain text replaces any styled title
        }
    }

    private func statusItemTitle(now: Date, statusItemDate: String, locale: Locale) -> String {
        guard settings.showDateTime else { return "" }

        if settings.useFuzzyTime && settings.showTime {
            return fuzzyTime(now)
        }

        if settings.showStatusSecondaryTime && settings.showTime {
            let zone = TimeZone(identifier: settings.statusSecondaryTimezone) ?? TimeZone(identifier: "GMT") ?? .current
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.timeZone = zone

            formatter.dateFormat = Self.timezoneDayFormat
            let zoneAndDay = formatter.string(from: now)
            formatter.dateFormat = settings.useStatusMilitary ? Self.timeFormatMilitary : Self.timeFormatNormal
            let zoneTime = formatter.string(from: now)

            // a status item can't show multiple lines, so combine the parts
            return "\(statusItemDate) | \(zoneAndDay) | \(zoneTime)"
        }

        return statusItemDate
    }

    /// The time in words, e.g. "Quarter past Three".
    private func fuzzyTime(_ now: Date) -> String {
        let hourNames = ["One", "Two", "Three", "Four", "Five", "Six",
                         "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"]
        let messages = [
            "%@ o'clock", "Five past %@", "Ten past %@", "Quarter past %@",
            "Twenty past %@", "Twenty Five past %@", "Half past %@", "Twenty Five to %@",
            "Twenty to %@", "Quarter to %@", "Ten to %@", "Five to %@",
        ]

        let components = Calendar.current.dateComponents([.hour, .minute], from: now)
        var hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        var index = 0
        if minutes > 2 {
            index = (minutes - 3) / 5 + 1
        }
        if hours < 1 {
            hours = 12
        }
        if minutes > 32 {
            hours += 1
        }
        return String(format: messages[index % 12], hourNames[(hours - 1) % 12])
    }

    /// True the first time it is asked, and whenever the user's calendar changes.
    private func isCalendarChanged() -> Bool {
        let current = Calendar.userCalendarIdentifier
        guard current != lastCalendarIdentifier else { return false }
        lastCalendarIdentifier = current
        return true
    }

    // MARK: - Configuration

    /// Applies the current settings to the window, calendar and clocks.
    private func configureWindow() {
        // reset last week to redraw
        lastWeek = -1

        // configure status item
        statusItemFormat = buildStatusItemDateFormatString()

        window.level = settings.useKeepTop ? .floating : .normal
        window.hidesOnDeactivate = settings.useAutoHide
        updateAutoHideMenuItem()

        // calendar
        calendarControl.showWeekNumbers = settings.showWeekNumbers
        calendarControl.showBoxes = settings.showCalendarBoxes
        calendarControl.hiliteColor = settings.useHiliteColor ? .systemRed : .controlAccentColor
        calendarControl.showEventIndicators = settings.showEvents
        calendarControl.showReminderIndicators = settings.showReminders
        calendarControl.useShadow = settings.useShadows
        calendarControl.fontSize = NSFont.systemFontSize + (settings.useLargeFonts ? 2 : 0)

        // the toolbar is only enabled if the calendar is showing
        if settings.showCalendar || settings.clockConfigs.isEmpty {
            resizeWindow()
            toolbarMenuItem.isEnabled = true
        } else {
            showToolbar = true
            toggleToolbar(self)
            toolbarMenuItem.isEnabled = false
        }

        // rebuild the clocks from the configuration
        for view in clockStack.arrangedSubviews {
            clockStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        clockItems = settings.clockConfigs.compactMap { config in
            guard !config.timezoneName.isEmpty, !config.title.isEmpty,
                  let zone = TimeZone(identifier: config.timezoneName) else { return nil }
            let clockItem = MZClockItem()
            clockItem.configure(
                caption: config.title, timeZone: zone, clockFace: settings.clockFaceName,
                useShadow: settings.useShadows, largeFonts: settings.useLargeFonts,
                seconds: config.useSeconds, militaryTime: settings.useMilitary)
            clockStack.addArrangedSubview(clockItem)
            return clockItem
        }

        // done painting
        settings.needsDisplay = false
    }

    // MARK: - Panels

    @IBAction func launchAboutBoxPanel(_ sender: Any?) {
        showAboutBox(help: false)
    }

    @IBAction func launchHelpPanel(_ sender: Any?) {
        showAboutBox(help: true)
    }

    private func showAboutBox(help: Bool) {
        let box = aboutBox ?? MZAboutBox()
        aboutBox = box
        box.showHelp(help)
        box.showWindow(self)
        bringForward(box.window)
    }

    @IBAction func openPreferences(_ sender: Any?) {
        let prefs = prefsWindow ?? MZVistaClockPreferences()
        prefsWindow = prefs
        prefs.showWindow(self)
        bringForward(prefs.window)
    }

    @IBAction func launchDateTimePreferencePanel(_ sender: Any?) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Date-Time-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    @IBAction func launchCalendar(_ sender: Any?) {
        launchApplication(bundleIdentifier: "com.apple.iCal", name: "Calendar")
    }

    @IBAction func launchReminders(_ sender: Any?) {
        launchApplication(bundleIdentifier: "com.apple.reminders", name: "Reminders")
    }

    private func launchApplication(bundleIdentifier: String, name: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            NSLog("%@ app not found", name)
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            if let error {
                NSLog("Failed to launch %@: %@", name, String(describing: error))
            }
        }
    }

    // MARK: - Calendar access

    /// Asks for calendar and reminders access the first time; quits if it was refused.
    private func requestCalendarAccess() {
        let store = EKEventStore()
        let eventStatus = EKEventStore.authorizationStatus(for: .event)
        let reminderStatus = EKEventStore.authorizationStatus(for: .reminder)

        if eventStatus == .notDetermined || reminderStatus == .notDetermined {
            Task {
                _ = try? await store.requestFullAccessToEvents()
                _ = try? await store.requestFullAccessToReminders()
                calendarControl.refreshIndicators()
            }
            return
        }

        let hasEventAccess = eventStatus == .fullAccess || eventStatus == .writeOnly
        let hasReminderAccess = reminderStatus == .fullAccess || reminderStatus == .writeOnly
        if !hasEventAccess || !hasReminderAccess {
            let alert = NSAlert()
            alert.messageText = "Access to calendar or reminder data has been denied!\n"
                + "Please enable access in System Settings and restart VistaClock."
            alert.runModal()
            NSApp.terminate(self)
        }
    }
}
