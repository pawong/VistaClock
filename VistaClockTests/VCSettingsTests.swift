//
//  VCSettingsTests.swift
//  VistaClockTests
//
//  Copyright © 2026 Mazookie, LLC. All rights reserved.
//

import Foundation
import Testing
@testable import VistaClock

/// Tests for the settings model and its archive format. These never touch the shared
/// settings instance or the file on disk.
struct VCSettingsTests {
    private func roundTrip(_ settings: VCSettings) throws -> VCSettings {
        let data = try NSKeyedArchiver.archivedData(withRootObject: settings, requiringSecureCoding: true)
        return try #require(try NSKeyedUnarchiver.unarchivedObject(ofClass: VCSettings.self, from: data))
    }

    @Test func defaultsMatchTheFactorySettings() {
        let settings = VCSettings()
        #expect(settings.useAutoHide)
        #expect(settings.useShadows)
        #expect(settings.showCalendar)
        #expect(settings.showDateTime)
        #expect(!settings.useMilitary)
        #expect(!settings.showDockIcon)
        #expect(settings.clockFaceName == "VCB01.png")
        #expect(settings.statusSecondaryTimezone == "GMT")
        #expect(settings.needsDisplay)
    }

    @Test func defaultClockIsPortland() throws {
        let clock = try #require(VCSettings().clockConfigs.first)
        #expect(VCSettings().clockConfigs.count == 1)
        #expect(clock.title == "Portland, OR")
        #expect(clock.timezoneName == "America/Los_Angeles")
        #expect(clock.useSeconds)
    }

    @Test func resetRestoresDefaults() {
        let settings = VCSettings()
        settings.useMilitary = true
        settings.showWeekNumbers = true
        settings.clockFaceName = "VCW03.png"
        settings.clockConfigs = []
        settings.reset()

        #expect(!settings.useMilitary)
        #expect(!settings.showWeekNumbers)
        #expect(settings.clockFaceName == "VCB01.png")
        #expect(settings.clockConfigs.count == 1)
    }

    @Test func archivePreservesEverySetting() throws {
        let original = VCSettings()
        original.floatRight = true
        original.useAutoLaunch = true
        original.useAutoHide = false
        original.useKeepTop = true
        original.useShadows = false
        original.useLargeFonts = true
        original.showDockIcon = true
        original.showDateTime = false
        original.useBWIcon = true
        original.showWeekNumberIcon = false
        original.useBWWeekIcon = true
        original.useInverseTitle = true
        original.useFuzzyTime = true
        original.showDate = false
        original.showMonth = false
        original.showStatusFullMonth = true
        original.showStatusWeekDay = true
        original.showTime = false
        original.showStatusSeconds = true
        original.useStatusMilitary = true
        original.showStatusAMPM = false
        original.showStatusSecondaryTime = true
        original.statusSecondaryTimezone = "Asia/Tokyo"
        original.useMilitary = true
        original.clockFaceName = "VCW05.png"
        original.showCalendar = false
        original.showWeekNumbers = true
        original.showEvents = true
        original.showReminders = true
        original.showCalendarBoxes = true
        original.useHiliteColor = true
        original.clockConfigs = [
            ClockConfig(title: "Tokyo", timezoneName: "Asia/Tokyo", useSeconds: false),
            ClockConfig(title: "London", timezoneName: "Europe/London", useSeconds: true),
        ]

        let copy = try roundTrip(original)

        #expect(copy.floatRight)
        #expect(copy.useAutoLaunch)
        #expect(!copy.useAutoHide)
        #expect(copy.useKeepTop)
        #expect(!copy.useShadows)
        #expect(copy.useLargeFonts)
        #expect(copy.showDockIcon)
        #expect(!copy.showDateTime)
        #expect(copy.useBWIcon)
        #expect(!copy.showWeekNumberIcon)
        #expect(copy.useBWWeekIcon)
        #expect(copy.useInverseTitle)
        #expect(copy.useFuzzyTime)
        #expect(!copy.showDate)
        #expect(!copy.showMonth)
        #expect(copy.showStatusFullMonth)
        #expect(copy.showStatusWeekDay)
        #expect(!copy.showTime)
        #expect(copy.showStatusSeconds)
        #expect(copy.useStatusMilitary)
        #expect(!copy.showStatusAMPM)
        #expect(copy.showStatusSecondaryTime)
        #expect(copy.statusSecondaryTimezone == "Asia/Tokyo")
        #expect(copy.useMilitary)
        #expect(copy.clockFaceName == "VCW05.png")
        #expect(!copy.showCalendar)
        #expect(copy.showWeekNumbers)
        #expect(copy.showEvents)
        #expect(copy.showReminders)
        #expect(copy.showCalendarBoxes)
        #expect(copy.useHiliteColor)
    }

    @Test func archivePreservesClockOrderAndFields() throws {
        let original = VCSettings()
        original.clockConfigs = [
            ClockConfig(title: "Tokyo", timezoneName: "Asia/Tokyo", useSeconds: false),
            ClockConfig(title: "London", timezoneName: "Europe/London", useSeconds: true),
        ]

        let clocks = try roundTrip(original).clockConfigs
        #expect(clocks.map(\.title) == ["Tokyo", "London"])
        #expect(clocks.map(\.timezoneName) == ["Asia/Tokyo", "Europe/London"])
        #expect(clocks.map(\.useSeconds) == [false, true])
    }

    @Test func unarchivedSettingsAreMarkedForRedraw() throws {
        let original = VCSettings()
        original.needsDisplay = false
        #expect(try roundTrip(original).needsDisplay)
    }

    @Test func archiveKeepsTheLegacyClassNames() throws {
        // Settings saved by the Objective-C version were archived under these class names.
        #expect(NSStringFromClass(VCSettings.self) == "VCSettings")
        #expect(NSStringFromClass(ClockConfig.self) == "MZClockConfig")
    }

    @Test func archiveURLIsACfgFileInLibrary() {
        let url = VCSettings.archiveURL
        #expect(url.pathExtension == "cfg")
        #expect(url.deletingLastPathComponent().lastPathComponent == "Library")
    }
}
