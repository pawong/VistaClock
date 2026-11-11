//
//  ClockListTests.swift
//  VistaClockTests
//
//  Copyright © 2026 Mazookie, LLC. All rights reserved.
//

import AppKit
import Foundation
import Testing
@testable import VistaClock

/// Tests for the Preferences clock list: adding, removing and drag-to-reorder.
/// Each test uses its own settings object, never the shared one.
@MainActor
struct ClockListTests {
    private func makePreferences(titles: [String]) -> (MZVistaClockPreferences, VCSettings) {
        let settings = VCSettings()
        settings.clockConfigs = titles.map { ClockConfig(title: $0, timezoneName: "GMT", useSeconds: false) }
        settings.needsDisplay = false
        return (MZVistaClockPreferences(settings: settings), settings)
    }

    // MARK: - Add and remove

    @Test func addingAClockAppendsOneForThisMacsTimeZone() {
        let (prefs, settings) = makePreferences(titles: ["A"])

        let row = prefs.addNewClock()

        #expect(row == 1)
        #expect(settings.clockConfigs.count == 2)
        let clock = settings.clockConfigs[1]
        #expect(clock.title == "New Clock")
        #expect(clock.timezoneName == TimeZone.current.identifier)
        #expect(!clock.useSeconds)
    }

    @Test func addingAClockRequestsARedraw() {
        let (prefs, settings) = makePreferences(titles: [])
        prefs.addNewClock()
        #expect(settings.needsDisplay)
    }

    @Test func removingAClockDropsOnlyThatRow() {
        let (prefs, settings) = makePreferences(titles: ["A", "B", "C"])
        prefs.removeClock(at: 1)
        #expect(settings.clockConfigs.map(\.title) == ["A", "C"])
        #expect(settings.needsDisplay)
    }

    @Test func removingTheLastClockLeavesAnEmptyList() {
        let (prefs, settings) = makePreferences(titles: ["A"])
        prefs.removeClock(at: 0)
        #expect(settings.clockConfigs.isEmpty)
    }

    @Test func removingAnInvalidRowChangesNothing() {
        let (prefs, settings) = makePreferences(titles: ["A", "B"])
        prefs.removeClock(at: -1)
        prefs.removeClock(at: 2)
        #expect(settings.clockConfigs.map(\.title) == ["A", "B"])
        #expect(!settings.needsDisplay)
    }

    // MARK: - Drag to reorder (the drop row is a gap between rows, counted before the move)

    @Test func draggingDownMovesPastTheGap() {
        let (prefs, settings) = makePreferences(titles: ["A", "B", "C", "D"])
        // drop A in the gap between C and D
        let index = prefs.moveClock(from: 0, toRow: 3)
        #expect(index == 2)
        #expect(settings.clockConfigs.map(\.title) == ["B", "C", "A", "D"])
    }

    @Test func draggingUpMovesBeforeTheGap() {
        let (prefs, settings) = makePreferences(titles: ["A", "B", "C", "D"])
        // drop D in the gap between A and B
        let index = prefs.moveClock(from: 3, toRow: 1)
        #expect(index == 1)
        #expect(settings.clockConfigs.map(\.title) == ["A", "D", "B", "C"])
    }

    @Test func draggingToTheTopAndBottom() {
        let (prefs, settings) = makePreferences(titles: ["A", "B", "C"])
        #expect(prefs.moveClock(from: 2, toRow: 0) == 0)
        #expect(settings.clockConfigs.map(\.title) == ["C", "A", "B"])

        #expect(prefs.moveClock(from: 0, toRow: 3) == 2)
        #expect(settings.clockConfigs.map(\.title) == ["A", "B", "C"])
    }

    @Test func droppingNextToItselfChangesNothing() {
        let (prefs, settings) = makePreferences(titles: ["A", "B", "C"])
        #expect(prefs.moveClock(from: 1, toRow: 1) == 1)
        #expect(prefs.moveClock(from: 1, toRow: 2) == 1)
        #expect(settings.clockConfigs.map(\.title) == ["A", "B", "C"])
    }

    @Test func reorderingKeepsEachClocksOwnSettings() {
        let settings = VCSettings()
        settings.clockConfigs = [
            ClockConfig(title: "Tokyo", timezoneName: "Asia/Tokyo", useSeconds: true),
            ClockConfig(title: "London", timezoneName: "Europe/London", useSeconds: false),
        ]
        let prefs = MZVistaClockPreferences(settings: settings)

        prefs.moveClock(from: 0, toRow: 2)

        let moved = settings.clockConfigs[1]
        #expect(moved.title == "Tokyo")
        #expect(moved.timezoneName == "Asia/Tokyo")
        #expect(moved.useSeconds)
    }

    @Test func reorderingRequestsARedraw() {
        let (prefs, settings) = makePreferences(titles: ["A", "B"])
        prefs.moveClock(from: 0, toRow: 2)
        #expect(settings.needsDisplay)
    }

    @Test func invalidDragSourceChangesNothing() {
        let (prefs, settings) = makePreferences(titles: ["A", "B"])
        #expect(prefs.moveClock(from: 5, toRow: 0) == nil)
        #expect(prefs.moveClock(from: -1, toRow: 0) == nil)
        #expect(settings.clockConfigs.map(\.title) == ["A", "B"])
        #expect(!settings.needsDisplay)
    }
}
