//
//  MZClockItem.swift
//  VistaClock
//
//  Created by Paul Wong on 5/27/14.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

import AppKit

/// One clock in the clock panel: caption, analog face, digital time and weekday.
final class MZClockItem: NSStackView {
    static let itemWidth: CGFloat = 146
    static let itemHeight: CGFloat = 214

    private let clock = MZClockControl()
    private let captionLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let dayLabel = NSTextField(labelWithString: "")

    private var timeZone = TimeZone.current
    private var useSeconds = false
    private var useMilitaryTime = false

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: Self.itemWidth, height: Self.itemHeight))

        orientation = .vertical
        alignment = .centerX
        spacing = 2
        edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

        for label in [captionLabel, timeLabel, dayLabel] {
            label.alignment = .center
            label.lineBreakMode = .byTruncatingTail
            label.translatesAutoresizingMaskIntoConstraints = false
        }

        clock.translatesAutoresizingMaskIntoConstraints = false
        setViews([captionLabel, clock, timeLabel, dayLabel], in: .center)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.itemWidth),
            heightAnchor.constraint(equalToConstant: Self.itemHeight),
            captionLabel.widthAnchor.constraint(equalTo: widthAnchor, constant: -8),
            timeLabel.widthAnchor.constraint(equalTo: widthAnchor, constant: -8),
            dayLabel.widthAnchor.constraint(equalTo: widthAnchor, constant: -8),
            clock.widthAnchor.constraint(equalToConstant: 138),
            clock.heightAnchor.constraint(equalToConstant: 138),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("MZClockItem is created in code")
    }

    // MARK: - Configuration

    func configure(caption: String, timeZone: TimeZone, clockFace: String, useShadow: Bool,
                   largeFonts: Bool, seconds: Bool, militaryTime: Bool) {
        captionLabel.stringValue = caption

        // hands must be chosen before the face so the right default hands load
        clock.usesWhiteHands = clockFace.hasPrefix("VCW")
        clock.setClockFace(named: clockFace)

        self.timeZone = timeZone
        useSeconds = seconds
        useMilitaryTime = militaryTime
        clock.showsSecondHand = seconds

        let shadow: NSShadow? = useShadow ? {
            let shadow = NSShadow()
            shadow.shadowOffset = NSSize(width: 1, height: 1)
            shadow.shadowBlurRadius = 1.5
            shadow.shadowColor = .shadowColor
            return shadow
        }() : nil
        for label in [captionLabel, timeLabel, dayLabel] {
            label.shadow = shadow
        }

        let bump: CGFloat = largeFonts ? 2 : 0
        captionLabel.font = .systemFont(ofSize: NSFont.systemFontSize + bump)
        timeLabel.font = .systemFont(ofSize: NSFont.systemFontSize + bump)
        dayLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize + (largeFonts ? 1 : 0))
    }

    /// Refreshes the digital readouts and the analog hands for `now`.
    func update(_ now: Date) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Locale.preferredLanguages.first ?? "en_US")
        formatter.timeZone = timeZone

        switch (useMilitaryTime, useSeconds) {
        case (true, true): formatter.dateFormat = "HH:mm:ss"
        case (true, false): formatter.dateFormat = "HH:mm"
        case (false, true): formatter.dateFormat = "h:mm:ss a"
        case (false, false): formatter.dateFormat = "h:mm a"
        }
        timeLabel.stringValue = formatter.string(from: now)

        formatter.dateFormat = "EEEE"
        dayLabel.stringValue = formatter.string(from: now)

        // The clock face reads the local time zone, so shift by the zone difference.
        let offset = timeZone.secondsFromGMT(for: now) - TimeZone.current.secondsFromGMT(for: now)
        clock.setTime(now.addingTimeInterval(TimeInterval(offset)))
    }

    /// The analog clock as an image (for the Dock icon).
    var image: NSImage? { clock.renderedImage() }
}
