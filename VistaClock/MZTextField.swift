//
//  MZTextField.swift
//  VistaClock
//
//  Created by Paul Wong on 1/14/16.
//  Copyright © 2026 Mazookie, LLC. All rights reserved.
//

import AppKit

/// A text field that handles the standard editing shortcuts itself (the app has
/// no Edit menu) and closes the clock window on Escape.
final class MZTextField: NSTextField {
    /// Called when the user presses Escape.
    var onCancel: (() -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {
            let responder = window?.firstResponder
            switch event.charactersIgnoringModifiers {
            case "x": return NSApp.sendAction(#selector(NSText.cut(_:)), to: responder, from: self)
            case "c": return NSApp.sendAction(#selector(NSText.copy(_:)), to: responder, from: self)
            case "v": return NSApp.sendAction(#selector(NSText.paste(_:)), to: responder, from: self)
            case "a": return NSApp.sendAction(#selector(NSText.selectAll(_:)), to: responder, from: self)
            default: break
            }
        }
        return super.performKeyEquivalent(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}
