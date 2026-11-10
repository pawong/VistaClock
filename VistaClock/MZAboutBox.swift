//
//  MZAboutBox.swift
//  VistaClock
//
//  Created by Paul Wong on 4/10/16.
//  Copyright © 2026 Mazookie, LLC. All rights reserved.
//

import AppKit

/// The About window, which also hosts the help text.
final class MZAboutBox: NSWindowController {
    private let aboutView = NSView()
    private let helpView = NSView()
    private let toggleButton = NSButton(title: "Help", target: nil, action: nil)
    private(set) var isHelpVisible = false

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 612, height: 293),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        window.title = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "VistaClock"
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)

        buildContent(in: window)
        showHelp(false)
    }

    required init?(coder: NSCoder) {
        fatalError("MZAboutBox is created in code")
    }

    // MARK: - Content

    private func buildContent(in window: NSWindow) {
        let info = Bundle.main.infoDictionary ?? [:]

        // about page
        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.imageScaling = .scaleProportionallyUpOrDown

        let title = NSTextField(labelWithString: info["CFBundleName"] as? String ?? "VistaClock")
        title.font = .systemFont(ofSize: 28, weight: .semibold)

        let version = NSTextField(labelWithString: String(
            format: NSLocalizedString("Version %@ (Build %@)", comment: "Version %@ (Build %@), displayed in the about window"),
            info["CFBundleShortVersionString"] as? String ?? "",
            info["CFBundleVersion"] as? String ?? ""))
        version.textColor = .secondaryLabelColor

        let acknowledgments = makeTextView(autohideScrollers: true)
        if let url = Bundle.main.url(forResource: "acknowledgments", withExtension: "txt"),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            acknowledgments.textView.string = text
            acknowledgments.textView.textColor = .labelColor
        }

        let copyright = NSTextField(labelWithString: info["NSHumanReadableCopyright"] as? String ?? "")
        copyright.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        copyright.textColor = .secondaryLabelColor

        let details = NSStackView(views: [title, version, acknowledgments.scrollView, copyright])
        details.orientation = .vertical
        details.alignment = .leading
        details.spacing = 8

        let about = NSStackView(views: [icon, details])
        about.orientation = .horizontal
        about.alignment = .top
        about.spacing = 20
        about.translatesAutoresizingMaskIntoConstraints = false
        aboutView.addSubview(about)

        // help page
        let help = makeTextView(autohideScrollers: false)
        if let url = Bundle.main.url(forResource: "help", withExtension: "rtfd"),
           let text = try? NSMutableAttributedString(url: url, options: [.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil) {
            help.textView.textStorage?.setAttributedString(text)
        }
        // The help document is authored for a white page, so it stays white in dark mode too.
        help.scrollView.appearance = NSAppearance(named: .aqua)
        help.scrollView.drawsBackground = true
        help.scrollView.backgroundColor = .white
        help.textView.drawsBackground = true
        help.textView.backgroundColor = .white
        help.scrollView.translatesAutoresizingMaskIntoConstraints = false
        helpView.addSubview(help.scrollView)

        // buttons
        let sourceButton = NSButton(title: "Source Code", target: self, action: #selector(openSourceCode(_:)))
        toggleButton.target = self
        toggleButton.action = #selector(toggleHelp(_:))
        let spacer = NSView()
        let buttons = NSStackView(views: [sourceButton, spacer, toggleButton])
        buttons.orientation = .horizontal
        buttons.distribution = .fill
        buttons.translatesAutoresizingMaskIntoConstraints = false

        guard let content = window.contentView else { return }
        for view in [aboutView, helpView, buttons] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
        }

        NSLayoutConstraint.activate([
            buttons.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            buttons.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            buttons.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12),

            aboutView.topAnchor.constraint(equalTo: content.topAnchor),
            aboutView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            aboutView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            aboutView.bottomAnchor.constraint(equalTo: buttons.topAnchor, constant: -12),

            helpView.topAnchor.constraint(equalTo: aboutView.topAnchor),
            helpView.leadingAnchor.constraint(equalTo: aboutView.leadingAnchor),
            helpView.trailingAnchor.constraint(equalTo: aboutView.trailingAnchor),
            helpView.bottomAnchor.constraint(equalTo: aboutView.bottomAnchor),

            about.topAnchor.constraint(equalTo: aboutView.topAnchor, constant: 20),
            about.leadingAnchor.constraint(equalTo: aboutView.leadingAnchor, constant: 20),
            about.trailingAnchor.constraint(equalTo: aboutView.trailingAnchor, constant: -20),
            about.bottomAnchor.constraint(equalTo: aboutView.bottomAnchor, constant: -8),

            icon.widthAnchor.constraint(equalToConstant: 210),
            icon.heightAnchor.constraint(equalToConstant: 210),
            acknowledgments.scrollView.widthAnchor.constraint(equalToConstant: 344),
            acknowledgments.scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),

            help.scrollView.topAnchor.constraint(equalTo: helpView.topAnchor),
            help.scrollView.leadingAnchor.constraint(equalTo: helpView.leadingAnchor),
            help.scrollView.trailingAnchor.constraint(equalTo: helpView.trailingAnchor),
            help.scrollView.bottomAnchor.constraint(equalTo: helpView.bottomAnchor),
        ])
    }

    private func makeTextView(autohideScrollers: Bool) -> (scrollView: NSScrollView, textView: NSTextView) {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = autohideScrollers
        scrollView.drawsBackground = false
        guard let textView = scrollView.documentView as? NSTextView else {
            return (scrollView, NSTextView())
        }
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 8, height: 8)
        return (scrollView, textView)
    }

    // MARK: - Actions

    @objc func openSourceCode(_ sender: Any?) {
        if let url = URL(string: "https://github.com/pawong/VistaClock") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func toggleHelp(_ sender: Any?) {
        showHelp(!isHelpVisible)
    }

    /// Shows the help page (true) or the about page (false).
    func showHelp(_ show: Bool) {
        isHelpVisible = show
        helpView.isHidden = !show
        aboutView.isHidden = show
        toggleButton.title = show ? "About" : "Help"
    }
}
