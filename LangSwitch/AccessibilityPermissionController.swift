//
//  AccessibilityPermissionController.swift
//  LangSwitch
//
//  Created by Vitalik Makhnev on 14.06.2026.
//

import ApplicationServices
import AppKit
import Foundation

final class AccessibilityPermissionController {
    private static let accessibilitySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )

    var isTrusted: Bool {
        return AXIsProcessTrusted()
    }

    func requestAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        openAccessibilitySettings()
    }

    func showAccessExplanationAndRequest() {
        let alert = NSAlert()
        alert.messageText = "Command switching was turned off."
        alert.informativeText = "Accessibility access is required to use Command switching without triggering during shortcuts like Cmd+C, Cmd+Tab, or Cmd+Space. In System Settings > Privacy & Security > Accessibility, turn on LangSwitch, then enable Command in LangSwitch again. If LangSwitch does not appear automatically, click + in the Accessibility list and add LangSwitch manually."
        alert.addButton(withTitle: "Grant Access")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            requestAccess()
        }
    }

    private func openAccessibilitySettings() {
        guard let accessibilitySettingsURL = Self.accessibilitySettingsURL else {
            return
        }

        NSWorkspace.shared.open(accessibilitySettingsURL)
    }
}
