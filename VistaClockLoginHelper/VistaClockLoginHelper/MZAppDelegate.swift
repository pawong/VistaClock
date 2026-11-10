//
//  MZAppDelegate.swift
//  VistaClockLoginHelper
//
//  Created by pwong on 8/10/12.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

import AppKit

/// Launches VistaClock at login (unless it is already running) and then quits.
///
/// This helper lives in VistaClock.app/Contents/Library/LoginItems.
@main
@MainActor
final class MZAppDelegate: NSObject, NSApplicationDelegate {
    private static let mainAppIdentifier = "com.Mazookie.VistaClock"

    static func main() {
        let delegate = MZAppDelegate()
        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let alreadyRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == Self.mainAppIdentifier
        }
        guard !alreadyRunning else {
            NSApp.terminate(nil)
            return
        }

        // .../VistaClock.app/Contents/Library/LoginItems/<this helper>.app
        let appURL = (0..<4).reduce(Bundle.main.bundleURL) { url, _ in url.deletingLastPathComponent() }

        NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            if let error {
                NSLog("Failed to launch app at %@: %@", appURL.path, String(describing: error))
            }
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }
}
