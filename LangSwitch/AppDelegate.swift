//
//  AppDelegate.swift
//  LangSwitch
//
//  Created by ANTON NIKEEV on 05.07.2023.
//  Modified by Vitalik Makhnev on 11.06.2026.
//

import AppKit
import Foundation
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private static let launchAtLoginPromptShownKey = "launchAtLogin.promptShown"

    private var statusBarMenuController: StatusBarMenuController?
    private let inputSourceSwitcher = InputSourceSwitcher()
    private let keyboardShortcutPreferences = KeyboardShortcutPreferences()
    private let accessibilityPermissionController = AccessibilityPermissionController()
    private let functionGlobeSystemBehaviorController = FunctionGlobeSystemBehaviorController()
    private var keyboardShortcutMonitor: KeyboardShortcutMonitor?
    private let longPressThreshold: TimeInterval = 0.2

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarMenuController = StatusBarMenuController(
            keyboardShortcutPreferences: keyboardShortcutPreferences,
            isLaunchAtLoginAvailable: { Self.isLaunchAtLoginAvailable },
            isLaunchAtLoginEnabled: { Self.isLaunchAtLoginEnabled },
            onModifierShortcutChangeRequested: { [weak self] shortcut, isEnabled in
                self?.setModifierShortcut(shortcut, isEnabled: isEnabled)
            },
            onLaunchAtLoginChangeRequested: { [weak self] isEnabled in
                self?.setLaunchAtLoginEnabled(isEnabled)
            },
            onExit: {
                NSApplication.shared.terminate(nil)
            }
        )

        NSApp.setActivationPolicy(.accessory)
        NSApp.hide(nil)

        disableCommandIfAccessibilityUnavailable(showWarning: true)
        disableFunctionGlobeIfUnavailable(showWarning: true)
        promptForLaunchAtLoginIfNeeded()
        configureKeyboardShortcutMonitor()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusBarMenuController?.showIcon()
        NSApp.setActivationPolicy(.accessory)
        NSApp.hide(nil)
        return false
    }

    private func configureKeyboardShortcutMonitor() {
        let triggers = keyboardShortcutPreferences.enabledShortcuts.map {
            $0.makeTrigger(longPressThreshold: longPressThreshold)
        }

        keyboardShortcutMonitor?.stop()

        guard !triggers.isEmpty else {
            keyboardShortcutMonitor = nil
            return
        }

        keyboardShortcutMonitor = KeyboardShortcutMonitor(
            triggers: triggers,
            onTrigger: { [weak self] in
                self?.inputSourceSwitcher.switchToNextInputSource()
            }
        )
        keyboardShortcutMonitor?.start()
    }

    private func setModifierShortcut(_ shortcut: KeyboardModifierShortcut, isEnabled: Bool) {
        guard isEnabled else {
            keyboardShortcutPreferences.setEnabled(false, for: shortcut)
            configureKeyboardShortcutMonitor()
            return
        }

        switch shortcut {
        case .command:
            guard accessibilityPermissionController.isTrusted else {
                keyboardShortcutPreferences.setEnabled(false, for: .command)
                configureKeyboardShortcutMonitor()
                showAccessibilityAccessWarning()
                return
            }

        case .functionGlobe:
            let availability = functionGlobeSystemBehaviorController.trackingAvailability()
            guard case .available = availability else {
                keyboardShortcutPreferences.setEnabled(false, for: .functionGlobe)
                configureKeyboardShortcutMonitor()
                if case .unavailable(let message) = availability {
                    showFunctionGlobeUnavailableWarning(message: message)
                }
                return
            }
        }

        keyboardShortcutPreferences.setEnabled(true, for: shortcut)
        configureKeyboardShortcutMonitor()
    }

    private func disableCommandIfAccessibilityUnavailable(showWarning: Bool) {
        guard keyboardShortcutPreferences.isEnabled(.command),
              !accessibilityPermissionController.isTrusted else {
            return
        }

        keyboardShortcutPreferences.setEnabled(false, for: .command)

        guard showWarning else {
            return
        }

        showAccessibilityAccessWarning()
    }

    private func disableFunctionGlobeIfUnavailable(showWarning: Bool) {
        guard keyboardShortcutPreferences.isEnabled(.functionGlobe) else {
            return
        }

        guard case .unavailable(let message) = functionGlobeSystemBehaviorController.trackingAvailability() else {
            return
        }

        keyboardShortcutPreferences.setEnabled(false, for: .functionGlobe)

        guard showWarning else {
            return
        }

        showFunctionGlobeUnavailableWarning(message: message)
    }

    private func showAccessibilityAccessWarning() {
        DispatchQueue.main.async { [weak self] in
            NSApp.activate(ignoringOtherApps: true)
            self?.accessibilityPermissionController.showAccessExplanationAndRequest()
        }
    }

    private func showFunctionGlobeUnavailableWarning(message: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            NSApp.activate(ignoringOtherApps: true)

            let alert = NSAlert()
            alert.messageText = "Fn/Globe switching was turned off."
            alert.informativeText = message
                ?? "macOS is using the Fn/Globe key for a system action. In System Settings > Keyboard, set Fn/Globe key action to Do Nothing, then enable Fn/Globe in LangSwitch again."
            alert.addButton(withTitle: "Open Keyboard Settings")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                self?.functionGlobeSystemBehaviorController.openKeyboardSettings()
            }
        }
    }

    private func promptForLaunchAtLoginIfNeeded() {
        guard Self.isLaunchAtLoginAvailable else {
            return
        }

        let userDefaults = UserDefaults.standard
        guard !userDefaults.bool(forKey: Self.launchAtLoginPromptShownKey) else {
            return
        }

        if Self.isLaunchAtLoginEnabled {
            userDefaults.set(true, forKey: Self.launchAtLoginPromptShownKey)
            return
        }

        DispatchQueue.main.async { [weak self] in
            NSApp.activate(ignoringOtherApps: true)

            let alert = NSAlert()
            alert.messageText = "Start LangSwitch at login?"
            alert.informativeText = "LangSwitch can start automatically when you sign in, so keyboard switching is available right away."
            alert.addButton(withTitle: "Start at Login")
            alert.addButton(withTitle: "Not Now")

            userDefaults.set(true, forKey: Self.launchAtLoginPromptShownKey)

            if alert.runModal() == .alertFirstButtonReturn {
                self?.setLaunchAtLoginEnabled(true)
            }
        }
    }

    private static var isLaunchAtLoginAvailable: Bool {
        if #available(macOS 13.0, *) {
            return true
        }

        return false
    }

    private static var isLaunchAtLoginEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }

        return false
    }

    private func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        guard Self.isLaunchAtLoginAvailable else {
            return
        }

        if #available(macOS 13.0, *) {
            do {
                let service = SMAppService.mainApp
                if isEnabled {
                    if service.status != .enabled && service.status != .requiresApproval {
                        try service.register()
                    }
                    if service.status == .requiresApproval {
                        showLaunchAtLoginApproval()
                    }
                } else if service.status == .enabled || service.status == .requiresApproval {
                    try service.unregister()
                }
            } catch {
                showLaunchAtLoginError(error)
            }
        }
    }

    @available(macOS 13.0, *)
    private func showLaunchAtLoginApproval() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)

            let alert = NSAlert()
            alert.messageText = "Allow LangSwitch to start at login"
            alert.informativeText = "macOS needs your approval. Open Login Items in System Settings and enable LangSwitch."
            alert.addButton(withTitle: "Open Login Items Settings")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                SMAppService.openSystemSettingsLoginItems()
            }
        }
    }

    private func showLaunchAtLoginError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Could not update Launch at Login."
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
