//
//  MZClockControl.swift
//  VistaClock
//
//  Created by Paul Wong on 6/7/14.
//  Copyright (c) 2026 Paul Wong. All rights reserved.
//

import AppKit

/// An analog clock drawn from the bundled face and hand images.
final class MZClockControl: NSView {
    private static let defaultFaceName = "VCB01.png"

    private(set) var time = Date()

    /// Whether the second hand is drawn.
    var showsSecondHand = false {
        didSet { needsDisplay = true }
    }

    /// White hands for dark faces, black hands otherwise.
    var usesWhiteHands = false

    private(set) var clockFaceName = MZClockControl.defaultFaceName
    private var faceImage: NSImage?
    private var dotImage: NSImage?
    private var secondHandImage: NSImage?
    private var minuteHandImage: NSImage?
    private var hourHandImage: NSImage?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setClockFace(named: MZClockControl.defaultFaceName)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setClockFace(named: MZClockControl.defaultFaceName)
    }

    override var isOpaque: Bool { false }

    // MARK: - Configuration

    func setTime(_ newTime: Date) {
        guard newTime != time else { return }
        time = newTime
        needsDisplay = true
    }

    /// Picks the face image and the matching hand images; falls back to the default
    /// face and the generic black/white hands when a face has no hands of its own.
    func setClockFace(named name: String) {
        clockFaceName = name
        faceImage = NSImage(named: name)
        if faceImage == nil {
            clockFaceName = MZClockControl.defaultFaceName
            faceImage = NSImage(named: clockFaceName)
        }

        if let dot = NSImage(named: "D" + clockFaceName) {
            dotImage = dot
            secondHandImage = NSImage(named: "S" + clockFaceName)
            minuteHandImage = NSImage(named: "M" + clockFaceName)
            hourHandImage = NSImage(named: "H" + clockFaceName)
        } else if usesWhiteHands {
            dotImage = NSImage(named: "DWVCB01.png")
            secondHandImage = NSImage(named: "SWVCB01.png")
            minuteHandImage = NSImage(named: "MWVCB01.png")
            hourHandImage = NSImage(named: "HWVCB01.png")
        } else {
            dotImage = NSImage(named: "DBVCB01.png")
            secondHandImage = NSImage(named: "SBVCB01.png")
            minuteHandImage = NSImage(named: "MBVCB01.png")
            hourHandImage = NSImage(named: "HBVCB01.png")
        }
        needsDisplay = true
    }

    /// The clock rendered to an image (used for the Dock icon).
    func renderedImage() -> NSImage? {
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        cacheDisplay(in: bounds, to: rep)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)
        return image
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        let diameter = min(bounds.width, bounds.height)
        let clockRect = NSRect(x: bounds.minX, y: bounds.minY, width: diameter, height: diameter)

        faceImage?.draw(in: clockRect, from: .zero, operation: .sourceOver, fraction: 1.0)

        // Hand angles, clockwise from 12 o'clock, in radians.
        let seconds = Double(time.seconds)
        let minutes = Double(time.minutes)
        let hours = Double(time.hours)
        let secondAngle = -(2 * .pi) * (seconds / 60)
        let minuteAngle = -(2 * .pi) * (minutes / 60 + seconds / 3600)
        let hourAngle = -(2 * .pi) * (hours / 12 + minutes / 720)

        let center = NSPoint(x: floor(clockRect.midX + 0.5), y: floor(clockRect.midY + 0.5))

        drawHand(hourHandImage, angle: hourAngle, center: center, diameter: diameter, fraction: 1.0)
        drawHand(minuteHandImage, angle: minuteAngle, center: center, diameter: diameter, fraction: 0.95)
        if showsSecondHand {
            drawHand(secondHandImage, angle: secondAngle, center: center, diameter: diameter, fraction: 0.9)
        }
        drawHand(dotImage, angle: secondAngle, center: center, diameter: diameter, fraction: 0.85)
    }

    /// Hand images are as tall as the clock face and rotate about their center.
    private func drawHand(_ image: NSImage?, angle: Double, center: NSPoint, diameter: CGFloat, fraction: CGFloat) {
        guard let image, image.size.height > 0, let context = NSGraphicsContext.current?.cgContext else { return }

        let scale = diameter / image.size.height
        let size = NSSize(width: image.size.width * scale, height: diameter)

        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: angle)
        image.draw(in: NSRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height),
                   from: .zero, operation: .sourceOver, fraction: fraction)
        context.restoreGState()
    }
}
