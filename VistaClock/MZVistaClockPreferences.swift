//
//  MZVistaClockPreferences.swift
//  VistaClock
//
//  Created by Paul Wong on 9/12/14.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

import AppKit

/// A toolbar-style tab controller that keeps the window titled "Preferences"
/// instead of switching the title to the selected tab's name.
private final class PreferencesTabViewController: NSTabViewController {
    override var title: String? {
        get { "Preferences" }
        set { }
    }
}

/// The preferences window: General, Menu Bar, Clock and Calendar pages.
final class MZVistaClockPreferences: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private typealias BoolSetting = ReferenceWritableKeyPath<VCSettings, Bool>

    private static let pageWidth: CGFloat = 460
    /// The clock page is wider so the time zone menu and Seconds column fit.
    private static let clockPageWidth: CGFloat = 540

    private let settings: VCSettings

    // controls bound to boolean settings
    private var checkboxes: [BoolSetting: NSButton] = [:]

    // time zones
    private struct ZoneChoice {
        let identifier: String
        let title: String
    }
    private let zones: [ZoneChoice]
    private let statusTimezonePopup = NSPopUpButton()

    // clock page
    private let clockFaces: [String]
    private var clockFaceIndex = 0
    private let clockPicker = MZClockControl()
    private let clockTable = NSTableView()
    private let addButton = NSButton()
    private let removeButton = NSButton()

    /// Pasteboard type used to drag clock rows into a new order.
    private static let clockRowType = NSPasteboard.PasteboardType("com.mazookie.vistaclock.clockrow")

    // MARK: - Setup

    init(settings: VCSettings = .shared) {
        self.settings = settings
        zones = TimeZone.knownTimeZoneIdentifiers.sorted().compactMap { identifier in
            guard let zone = TimeZone(identifier: identifier) else { return nil }
            let minutes = zone.secondsFromGMT() / 60
            let sign = minutes < 0 ? "-" : "+"
            let title = String(format: "%@  (GMT%@%d:%02d)", identifier, sign, abs(minutes) / 60, abs(minutes) % 60)
            return ZoneChoice(identifier: identifier, title: title)
        }

        // clock faces are the bundled VC*.png images
        let resources = Bundle.main.resourcePath.flatMap { try? FileManager.default.contentsOfDirectory(atPath: $0) } ?? []
        clockFaces = resources.filter { $0.hasPrefix("VC") && $0.hasSuffix(".png") }.sorted()

        let tabs = PreferencesTabViewController()
        tabs.tabStyle = .toolbar
        let window = NSWindow(contentViewController: tabs)
        window.title = "Preferences"
        window.titleVisibility = .visible
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.canHide = false
        super.init(window: window)
        window.delegate = self

        fillZonePopup(statusTimezonePopup)

        tabs.addTabViewItem(page("General", symbol: "gearshape", views: generalPage()))
        tabs.addTabViewItem(page("Menu Bar", symbol: "menubar.rectangle", views: menuBarPage()))
        tabs.addTabViewItem(page("Clock", symbol: "clock", width: Self.clockPageWidth, views: clockPage()))
        tabs.addTabViewItem(page("Calendar", symbol: "calendar", views: calendarPage()))

        updateWindowControls()
    }

    required init?(coder: NSCoder) {
        fatalError("MZVistaClockPreferences is created in code")
    }

    // MARK: - Page building

    private func page(_ title: String, symbol: String, width: CGFloat = pageWidth, views: [NSView]) -> NSTabViewItem {
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: width),
        ])

        let controller = NSViewController()
        controller.view = container

        // Tell the tab controller how big this page is so the window resizes to fit each tab.
        container.layoutSubtreeIfNeeded()
        controller.preferredContentSize = container.fittingSize
        let item = NSTabViewItem(viewController: controller)
        item.label = title
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        return item
    }

    private func checkbox(_ title: String, _ setting: BoolSetting) -> NSButton {
        let button = NSButton(checkboxWithTitle: title, target: self, action: #selector(updateSettings(_:)))
        checkboxes[setting] = button
        return button
    }

    /// Dependent options, indented under the option that controls them.
    private func indented(_ views: [NSView]) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        // never absorb extra height when the page is taller than its content
        stack.setHuggingPriority(.required, for: .vertical)
        return stack
    }

    private func generalPage() -> [NSView] {
        [
            checkbox("Automatically Start VistaClock at Login", \.useAutoLaunch),
            checkbox("Automatically Hide VistaClock", \.useAutoHide),
            checkbox("Keep on Top", \.useKeepTop),
            checkbox("Use Shadows", \.useShadows),
            checkbox("Use Large Fonts", \.useLargeFonts),
            checkbox("Show Dock Clock", \.showDockIcon),
        ]
    }

    private func menuBarPage() -> [NSView] {
        statusTimezonePopup.target = self
        statusTimezonePopup.action = #selector(updateSettings(_:))

        return [
            checkbox("Show Week Number Icon", \.showWeekNumberIcon),
            indented([checkbox("Use Black & White Week Number Icon", \.useBWWeekIcon)]),
            checkbox("Use Black & White Icon", \.useBWIcon),
            checkbox("Enable Date Time Options", \.showDateTime),
            indented([
                checkbox("Use Inverse Color", \.useInverseTitle),
                checkbox("Use Fuzzy Time", \.useFuzzyTime),
                checkbox("Show Date", \.showDate),
                indented([
                    checkbox("Show Month", \.showMonth),
                    indented([checkbox("Show Full Month Name", \.showStatusFullMonth)]),
                    checkbox("Show Day of the Week", \.showStatusWeekDay),
                ]),
                checkbox("Show Time", \.showTime),
                indented([
                    checkbox("Display With Seconds", \.showStatusSeconds),
                    checkbox("Use a 24-hour Clock", \.useStatusMilitary),
                    checkbox("Show AM/PM", \.showStatusAMPM),
                    checkbox("Show Secondary Clock", \.showStatusSecondaryTime),
                    indented([statusTimezonePopup]),
                ]),
            ]),
        ]
    }

    private func clockPage() -> [NSView] {
        // face picker
        let previous = NSButton(image: NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Previous Clock Face") ?? NSImage(),
                                target: self, action: #selector(movePreviousClockFace(_:)))
        let next = NSButton(image: NSImage(systemSymbolName: "chevron.right", accessibilityDescription: "Next Clock Face") ?? NSImage(),
                            target: self, action: #selector(moveNextClockFace(_:)))
        clockPicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            clockPicker.widthAnchor.constraint(equalToConstant: 96),
            clockPicker.heightAnchor.constraint(equalToConstant: 96),
        ])
        let picker = NSStackView(views: [previous, clockPicker, next, checkbox("Use a 24-hour clock", \.useMilitary)])
        picker.alignment = .centerY
        picker.spacing = 12
        picker.setCustomSpacing(24, after: next)

        // configured clocks
        let columns: [(id: String, title: String, width: CGFloat)] = [
            ("name", "Name", 140), ("zone", "Time Zone", 250), ("seconds", "Seconds", 70),
        ]
        for column in columns {
            let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(column.id))
            tableColumn.title = column.title
            tableColumn.width = column.width
            clockTable.addTableColumn(tableColumn)
        }
        clockTable.dataSource = self
        clockTable.delegate = self
        clockTable.usesAlternatingRowBackgroundColors = true
        clockTable.rowHeight = 26
        // extra or missing width goes to the name, so the zone menu and Seconds keep their size
        clockTable.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle

        // drag rows to reorder
        clockTable.registerForDraggedTypes([Self.clockRowType])
        clockTable.setDraggingSourceOperationMask(.move, forLocal: true)
        clockTable.draggingDestinationFeedbackStyle = .gap

        let scroll = NSScrollView()
        scroll.documentView = clockTable
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.widthAnchor.constraint(equalToConstant: Self.clockPageWidth - 40),
            scroll.heightAnchor.constraint(equalToConstant: 150),
        ])

        configure(addButton, symbol: "plus", help: "Add Clock", action: #selector(addClock(_:)))
        configure(removeButton, symbol: "minus", help: "Remove Clock", action: #selector(removeClockConfig(_:)))
        let listButtons = NSStackView(views: [addButton, removeButton])
        listButtons.spacing = 4

        return [
            picker,
            scroll,
            listButtons,
        ]
    }

    private func calendarPage() -> [NSView] {
        [
            checkbox("Show Calendar", \.showCalendar),
            indented([
                checkbox("Show Week Number Column", \.showWeekNumbers),
                checkbox("Show Event Indicators", \.showEvents),
                checkbox("Show Reminder Indicators", \.showReminders),
                checkbox("Show Boxes", \.showCalendarBoxes),
                checkbox("Use Red Highlights", \.useHiliteColor),
            ]),
        ]
    }

    private func configure(_ button: NSButton, symbol: String, help: String, action: Selector) {
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: help)
        button.toolTip = help
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = action
    }

    // MARK: - Time zones

    private func fillZonePopup(_ popup: NSPopUpButton) {
        popup.removeAllItems()
        for zone in zones {
            let item = NSMenuItem(title: zone.title, action: nil, keyEquivalent: "")
            item.representedObject = zone.identifier
            popup.menu?.addItem(item)
        }
    }

    private func select(zone identifier: String, in popup: NSPopUpButton) {
        if let index = popup.itemArray.firstIndex(where: { ($0.representedObject as? String) == identifier }) {
            popup.selectItem(at: index)
        } else if !identifier.isEmpty {
            // a saved zone this system doesn't list: show it rather than silently picking another
            let item = NSMenuItem(title: identifier, action: nil, keyEquivalent: "")
            item.representedObject = identifier
            popup.menu?.insertItem(item, at: 0)
            popup.selectItem(at: 0)
        } else {
            popup.selectItem(at: 0)
        }
    }

    // MARK: - Clock list

    func numberOfRows(in tableView: NSTableView) -> Int {
        settings.clockConfigs.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn, settings.clockConfigs.indices.contains(row) else { return nil }
        let config = settings.clockConfigs[row]
        let identifier = tableColumn.identifier

        switch identifier.rawValue {
        case "seconds":
            let button = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSButton ?? {
                let button = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleSeconds(_:)))
                button.identifier = identifier
                return button
            }()
            button.state = config.useSeconds ? .on : .off
            return button

        case "zone":
            let popup = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSPopUpButton ?? {
                let popup = NSPopUpButton()
                popup.identifier = identifier
                popup.controlSize = .small
                popup.target = self
                popup.action = #selector(zoneChosen(_:))
                fillZonePopup(popup)
                return popup
            }()
            select(zone: config.timezoneName, in: popup)
            return popup

        default:
            // the name edits in place, centered vertically in the row
            let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView ?? {
                let cell = NSTableCellView()
                cell.identifier = identifier
                let field = NSTextField()
                field.translatesAutoresizingMaskIntoConstraints = false
                field.isEditable = true
                field.isBordered = false
                field.drawsBackground = false
                field.focusRingType = .none
                field.lineBreakMode = .byTruncatingTail
                field.cell?.sendsActionOnEndEditing = true
                field.target = self
                field.action = #selector(nameEdited(_:))
                cell.addSubview(field)
                cell.textField = field
                NSLayoutConstraint.activate([
                    field.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                    field.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
                    field.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                ])
                return cell
            }()
            cell.textField?.stringValue = config.title
            return cell
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateListButtons()
    }

    private func updateListButtons() {
        removeButton.isEnabled = clockTable.selectedRow >= 0
    }

    private func clocksChanged(select row: Int? = nil) {
        clockTable.reloadData()
        if let row {
            clockTable.selectRowIndexes([row], byExtendingSelection: false)
        }
        updateListButtons()
        settings.needsDisplay = true
    }

    /// Adds a clock for this Mac's time zone and starts editing its name.
    @objc private func addClock(_ sender: Any?) {
        let row = addNewClock()
        clockTable.scrollRowToVisible(row)

        if let field = (clockTable.view(atColumn: 0, row: row, makeIfNecessary: true) as? NSTableCellView)?.textField {
            window?.makeFirstResponder(field)
            field.selectText(nil)
        }
    }

    /// Appends a clock for this Mac's time zone, selects it, and returns its row.
    @discardableResult
    func addNewClock() -> Int {
        settings.clockConfigs.append(ClockConfig(
            title: "New Clock", timezoneName: TimeZone.current.identifier, useSeconds: false))
        let row = settings.clockConfigs.count - 1
        clocksChanged(select: row)
        return row
    }

    /// Removes the clock at `row` and keeps a neighbor selected.
    func removeClock(at row: Int) {
        guard settings.clockConfigs.indices.contains(row) else { return }
        settings.clockConfigs.remove(at: row)
        clocksChanged(select: settings.clockConfigs.isEmpty ? nil : min(row, settings.clockConfigs.count - 1))
    }

    @objc private func removeClockConfig(_ sender: Any?) {
        removeClock(at: clockTable.selectedRow)
    }

    @objc private func nameEdited(_ sender: NSTextField) {
        let row = clockTable.row(for: sender)
        guard settings.clockConfigs.indices.contains(row) else { return }
        settings.clockConfigs[row].title = sender.stringValue
        settings.needsDisplay = true
    }

    @objc private func zoneChosen(_ sender: NSPopUpButton) {
        let row = clockTable.row(for: sender)
        guard settings.clockConfigs.indices.contains(row),
              let identifier = sender.selectedItem?.representedObject as? String else { return }
        settings.clockConfigs[row].timezoneName = identifier
        settings.needsDisplay = true
    }

    // MARK: Drag to reorder

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? {
        let item = NSPasteboardItem()
        item.setString(String(row), forType: Self.clockRowType)
        return item
    }

    func tableView(_ tableView: NSTableView, validateDrop info: any NSDraggingInfo,
                   proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        // only rows from this table, dropped between rows
        guard (info.draggingSource as? NSTableView) === tableView else { return [] }
        tableView.setDropRow(row, dropOperation: .above)
        return .move
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo,
                   row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let text = info.draggingPasteboard.pasteboardItems?.first?.string(forType: Self.clockRowType),
              let from = Int(text) else { return false }
        return moveClock(from: from, toRow: row) != nil
    }

    /// Moves the clock at `from` to the gap before `row` (a drop position counted with the
    /// dragged clock still in place) and returns its new index, or nil if `from` is invalid.
    @discardableResult
    func moveClock(from: Int, toRow row: Int) -> Int? {
        guard settings.clockConfigs.indices.contains(from) else { return nil }

        // moving later in the list shifts everything after the dragged row up by one
        let destination = from < row ? row - 1 : row
        let clock = settings.clockConfigs.remove(at: from)
        let index = min(max(destination, 0), settings.clockConfigs.count)
        settings.clockConfigs.insert(clock, at: index)
        clocksChanged(select: index)
        return index
    }

    @objc private func toggleSeconds(_ sender: NSButton) {
        let row = clockTable.row(for: sender)
        guard settings.clockConfigs.indices.contains(row) else { return }
        settings.clockConfigs[row].useSeconds = sender.state == .on
        settings.needsDisplay = true
    }

    // MARK: - Settings

    /// Pushes the current settings into the controls.
    func updateWindowControls() {
        for (setting, button) in checkboxes {
            button.state = settings[keyPath: setting] ? .on : .off
        }
        select(zone: settings.statusSecondaryTimezone, in: statusTimezonePopup)

        clockFaceIndex = clockFaces.firstIndex(of: settings.clockFaceName) ?? 0
        updateClockPicker()
        clockTable.reloadData()
        updateListButtons()
        setEnabledItems()
    }

    /// Reads the controls into the shared settings and applies them.
    @objc func updateSettings(_ sender: Any?) {
        for (setting, button) in checkboxes {
            settings[keyPath: setting] = button.state == .on
        }
        settings.statusSecondaryTimezone = statusTimezonePopup.selectedItem?.representedObject as? String ?? "GMT"
        if clockFaces.indices.contains(clockFaceIndex) {
            settings.clockFaceName = clockFaces[clockFaceIndex]
        }

        setEnabledItems()
        LoginItemHelper.setLoginItemEnabled(settings.useAutoLaunch)
        NSApp.setActivationPolicy(settings.showDockIcon ? .regular : .accessory)
        settings.needsDisplay = true
    }

    /// Enables and disables options that depend on other options.
    private func setEnabledItems() {
        func enable(_ setting: BoolSetting, _ enabled: Bool) {
            checkboxes[setting]?.isEnabled = enabled
        }

        let dateTime = settings.showDateTime
        let fuzzy = settings.useFuzzyTime
        let date = settings.showDate
        let time = settings.showTime

        enable(\.useBWIcon, !dateTime && !settings.showWeekNumberIcon)
        enable(\.useInverseTitle, dateTime)
        enable(\.useFuzzyTime, dateTime)
        enable(\.showDate, dateTime && !fuzzy)
        enable(\.showMonth, dateTime && date && !fuzzy)
        enable(\.showStatusFullMonth, dateTime && date && !fuzzy)
        enable(\.showStatusWeekDay, dateTime && date && !fuzzy)
        enable(\.showTime, dateTime && !fuzzy)
        enable(\.showStatusSeconds, dateTime && time && !fuzzy)
        enable(\.useStatusMilitary, dateTime && time && !fuzzy)
        enable(\.showStatusAMPM, dateTime && time && !fuzzy)
        enable(\.showStatusSecondaryTime, dateTime && time && !fuzzy)
        statusTimezonePopup.isEnabled = dateTime && time && !fuzzy
        enable(\.useBWWeekIcon, settings.showWeekNumberIcon)

        if dateTime {
            enable(\.useBWIcon, !date && !time && !fuzzy)
            enable(\.showStatusAMPM, !settings.useStatusMilitary && time && !fuzzy)
            enable(\.showStatusFullMonth, settings.showMonth && date && !fuzzy)
            enable(\.useInverseTitle, date || time || fuzzy)
            statusTimezonePopup.isEnabled = settings.showStatusSecondaryTime && !fuzzy
        }

        enable(\.useKeepTop, !settings.useAutoHide)

        for setting in [\.showWeekNumbers, \.showEvents, \.showReminders, \.showCalendarBoxes, \.useHiliteColor] as [BoolSetting] {
            enable(setting, settings.showCalendar)
        }
    }

    // MARK: - Clock face picker

    @objc private func moveNextClockFace(_ sender: Any?) {
        guard clockFaceIndex < clockFaces.count - 1 else { return }
        clockFaceIndex += 1
        updateClockPicker()
        updateSettings(nil)
    }

    @objc private func movePreviousClockFace(_ sender: Any?) {
        guard clockFaceIndex > 0 else { return }
        clockFaceIndex -= 1
        updateClockPicker()
        updateSettings(nil)
    }

    private func updateClockPicker() {
        if clockFaces.indices.contains(clockFaceIndex) {
            let name = clockFaces[clockFaceIndex]
            clockPicker.usesWhiteHands = name.hasPrefix("VCW")
            clockPicker.setClockFace(named: name)
        }
        clockPicker.setTime(Date())
    }

    // MARK: - Window

    /// Save settings before closing.
    func windowWillClose(_ notification: Notification) {
        settings.archive()
    }
}
