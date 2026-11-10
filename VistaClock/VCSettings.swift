//
//  VCSettings.swift
//  VistaClock
//
//  Created by Paul Wong on 9/12/14.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

import Foundation

/// One clock shown in the clock panel.
///
/// The Objective-C names are kept so settings archived by earlier versions still decode.
@objc(MZClockConfig)
final class ClockConfig: NSObject, NSSecureCoding, @unchecked Sendable {
    static var supportsSecureCoding: Bool { true }

    var title: String
    var timezoneName: String
    var useSeconds: Bool

    init(title: String, timezoneName: String, useSeconds: Bool) {
        self.title = title
        self.timezoneName = timezoneName
        self.useSeconds = useSeconds
        super.init()
    }

    required init?(coder: NSCoder) {
        title = coder.decodeObject(of: NSString.self, forKey: "title") as String? ?? ""
        timezoneName = coder.decodeObject(of: NSString.self, forKey: "timezone") as String? ?? ""
        useSeconds = coder.decodeBool(forKey: "seconds")
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(title as NSString, forKey: "title")
        coder.encode(timezoneName as NSString, forKey: "timezone")
        coder.encode(useSeconds, forKey: "seconds")
    }
}

/// All user preferences, archived to ~/Library/<AppName>.cfg.
///
/// Used from the main thread only.
@objc(VCSettings)
final class VCSettings: NSObject, NSSecureCoding, @unchecked Sendable {
    static var supportsSecureCoding: Bool { true }

    // other settings
    var needsDisplay = true
    var floatRight = false

    // general panel settings
    var useAutoLaunch = false
    var useAutoHide = true
    var useKeepTop = false
    var useShadows = true
    var useLargeFonts = false
    var showDockIcon = false

    // menubar panel settings
    var showDateTime = true
    var useBWIcon = false
    var showWeekNumberIcon = true
    var useBWWeekIcon = false
    var useInverseTitle = false
    var useFuzzyTime = false

    var showDate = true
    var showMonth = true
    var showStatusFullMonth = false
    var showStatusWeekDay = false

    var showTime = true
    var showStatusSeconds = false
    var useStatusMilitary = false
    var showStatusAMPM = true
    var showStatusSecondaryTime = false
    var statusSecondaryTimezone = "GMT"

    // clock settings
    var useMilitary = false
    var clockFaceName = "VCB01.png"
    var clockConfigs: [ClockConfig] = []

    // calendar settings
    var showCalendar = true
    var showWeekNumbers = false
    var showEvents = false
    var showReminders = false
    var showCalendarBoxes = false
    var useHiliteColor = false

    // MARK: - Shared instance

    nonisolated(unsafe) private static var instance: VCSettings?

    static var shared: VCSettings {
        if let instance { return instance }

        var loaded: VCSettings?
        if let data = try? Data(contentsOf: archiveURL) {
            do {
                loaded = try NSKeyedUnarchiver.unarchivedObject(ofClass: VCSettings.self, from: data)
            } catch {
                NSLog("Failed to unarchive VCSettings: %@", String(describing: error))
            }
        }

        let settings = loaded ?? VCSettings()
        instance = settings
        return settings
    }

    static var archiveURL: URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let name = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? "VistaClock"
        return library.appendingPathComponent("\(name).cfg")
    }

    // MARK: - Lifecycle

    override init() {
        super.init()
        reset()
    }

    /// Restores the factory defaults.
    func reset() {
        needsDisplay = true
        floatRight = false

        useAutoLaunch = false
        useAutoHide = true
        useKeepTop = false
        useShadows = true
        useLargeFonts = false
        showDockIcon = false
        useInverseTitle = false

        showDateTime = true
        useBWIcon = false
        showWeekNumberIcon = true
        useBWWeekIcon = false
        useFuzzyTime = false

        showDate = true
        showMonth = true
        showStatusFullMonth = false
        showStatusWeekDay = false

        showTime = true
        showStatusSeconds = false
        useStatusMilitary = false
        showStatusAMPM = true
        showStatusSecondaryTime = false
        statusSecondaryTimezone = "GMT"

        showCalendar = true
        showWeekNumbers = false
        showEvents = false
        showReminders = false
        showCalendarBoxes = false
        useHiliteColor = false

        useMilitary = false
        clockFaceName = "VCB01.png"
        clockConfigs = [ClockConfig(title: "Portland, OR", timezoneName: "America/Los_Angeles", useSeconds: true)]
    }

    func archive() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
            try data.write(to: VCSettings.archiveURL, options: .atomic)
        } catch {
            NSLog("Failed to save VCSettings: %@", String(describing: error))
        }
    }

    // MARK: - NSCoding

    required init?(coder: NSCoder) {
        super.init()

        floatRight = coder.decodeBool(forKey: "floatRight")

        useAutoLaunch = coder.decodeBool(forKey: "useAutoLaunch")
        useAutoHide = coder.decodeBool(forKey: "useAutoHide")
        useKeepTop = coder.decodeBool(forKey: "useKeepTop")
        useShadows = coder.decodeBool(forKey: "useShadows")
        useLargeFonts = coder.decodeBool(forKey: "useLargeFonts")
        showDockIcon = coder.decodeBool(forKey: "showDockIcon")

        showDateTime = coder.decodeBool(forKey: "showDateTime")
        useBWIcon = coder.decodeBool(forKey: "useBWIcon")
        showWeekNumberIcon = coder.decodeBool(forKey: "showWeekNumberIcon")
        useBWWeekIcon = coder.decodeBool(forKey: "useBWWeekIcon")
        useInverseTitle = coder.decodeBool(forKey: "useInverseTitle")
        useFuzzyTime = coder.decodeBool(forKey: "useFuzzyTime")

        showDate = coder.decodeBool(forKey: "showDate")
        showMonth = coder.decodeBool(forKey: "showMonth")
        showStatusFullMonth = coder.decodeBool(forKey: "showStatusFullMonth")
        showStatusWeekDay = coder.decodeBool(forKey: "showStatusWeekDay")

        showTime = coder.decodeBool(forKey: "showTime")
        showStatusSeconds = coder.decodeBool(forKey: "showStatusSeconds")
        useStatusMilitary = coder.decodeBool(forKey: "useStatusMilitary")
        showStatusAMPM = coder.decodeBool(forKey: "showStatusAMPM")
        showStatusSecondaryTime = coder.decodeBool(forKey: "showStatusSecondaryTime")
        statusSecondaryTimezone = coder.decodeObject(of: NSString.self, forKey: "statusSecondaryTimezone") as String? ?? "GMT"

        useMilitary = coder.decodeBool(forKey: "useMilitary")
        clockFaceName = coder.decodeObject(of: NSString.self, forKey: "clockFace") as String? ?? "VCB01.png"
        clockConfigs = coder.decodeArrayOfObjects(ofClass: ClockConfig.self, forKey: "clockConfigs") ?? []

        showCalendar = coder.decodeBool(forKey: "showCalendar")
        showWeekNumbers = coder.decodeBool(forKey: "showWeekNumbers")
        showEvents = coder.decodeBool(forKey: "showEvents")
        showReminders = coder.decodeBool(forKey: "showReminders")
        showCalendarBoxes = coder.decodeBool(forKey: "showCalendarBoxes")
        useHiliteColor = coder.decodeBool(forKey: "useHiliteColor")

        needsDisplay = true
    }

    func encode(with coder: NSCoder) {
        coder.encode(floatRight, forKey: "floatRight")
        coder.encode(clockConfigs as NSArray, forKey: "clockConfigs")

        coder.encode(useAutoLaunch, forKey: "useAutoLaunch")
        coder.encode(useAutoHide, forKey: "useAutoHide")
        coder.encode(useKeepTop, forKey: "useKeepTop")
        coder.encode(useInverseTitle, forKey: "useInverseTitle")
        coder.encode(useShadows, forKey: "useShadows")
        coder.encode(useLargeFonts, forKey: "useLargeFonts")
        coder.encode(showDockIcon, forKey: "showDockIcon")

        coder.encode(showDateTime, forKey: "showDateTime")
        coder.encode(useBWIcon, forKey: "useBWIcon")
        coder.encode(showWeekNumberIcon, forKey: "showWeekNumberIcon")
        coder.encode(useBWWeekIcon, forKey: "useBWWeekIcon")
        coder.encode(useFuzzyTime, forKey: "useFuzzyTime")

        coder.encode(showDate, forKey: "showDate")
        coder.encode(showMonth, forKey: "showMonth")
        coder.encode(showStatusFullMonth, forKey: "showStatusFullMonth")
        coder.encode(showStatusWeekDay, forKey: "showStatusWeekDay")

        coder.encode(showTime, forKey: "showTime")
        coder.encode(showStatusSeconds, forKey: "showStatusSeconds")
        coder.encode(useStatusMilitary, forKey: "useStatusMilitary")
        coder.encode(showStatusAMPM, forKey: "showStatusAMPM")
        coder.encode(showStatusSecondaryTime, forKey: "showStatusSecondaryTime")
        coder.encode(statusSecondaryTimezone as NSString, forKey: "statusSecondaryTimezone")

        coder.encode(useMilitary, forKey: "useMilitary")
        coder.encode(clockFaceName as NSString, forKey: "clockFace")

        coder.encode(showCalendar, forKey: "showCalendar")
        coder.encode(showWeekNumbers, forKey: "showWeekNumbers")
        coder.encode(showEvents, forKey: "showEvents")
        coder.encode(showReminders, forKey: "showReminders")
        coder.encode(showCalendarBoxes, forKey: "showCalendarBoxes")
        coder.encode(useHiliteColor, forKey: "useHiliteColor")
    }
}
