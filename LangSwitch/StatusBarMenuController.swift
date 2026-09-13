//
//  StatusBarMenuController.swift
//  LangSwitch
//
//  Created by Vitalik Makhnev on 11.06.2026.
//

import AppKit
import Foundation

final class StatusBarMenuController: NSObject, NSMenuDelegate {
    private static let hideStatusBarIconKey = "hideStatusBarIcon"
    private static let modifierShortcutsItemIdentifier = NSUserInterfaceItemIdentifier("modifierShortcuts")
    private static let tapDurationItemIdentifier = NSUserInterfaceItemIdentifier("tapDuration")
    private static let resumeItemIdentifier = NSUserInterfaceItemIdentifier("resumeKeyboardSwitching")
    private static let launchAtLoginItemIdentifier = NSUserInterfaceItemIdentifier("launchAtLogin")

    private let statusBarItem: NSStatusItem
    private let userDefaults: UserDefaults
    private let aboutWindowController = AboutWindowController()
    private let keyboardShortcutPreferences: KeyboardShortcutPreferences
    private let isLaunchAtLoginAvailable: () -> Bool
    private let isLaunchAtLoginEnabled: () -> Bool
    private let onModifierShortcutChangeRequested: (KeyboardModifierShortcut, Bool) -> Void
    private let onTapDurationChangeRequested: (TimeInterval) -> Void
    private let onKeyboardSwitchingStatusRequested: () -> Bool
    private let onResumeKeyboardSwitching: () -> Void
    private let onLaunchAtLoginChangeRequested: (Bool) -> Void
    private let onExit: () -> Void

    init(userDefaults: UserDefaults = .standard,
         keyboardShortcutPreferences: KeyboardShortcutPreferences,
         isLaunchAtLoginAvailable: @escaping () -> Bool,
         isLaunchAtLoginEnabled: @escaping () -> Bool,
         onModifierShortcutChangeRequested: @escaping (KeyboardModifierShortcut, Bool) -> Void,
         onTapDurationChangeRequested: @escaping (TimeInterval) -> Void,
         onKeyboardSwitchingStatusRequested: @escaping () -> Bool,
         onResumeKeyboardSwitching: @escaping () -> Void,
         onLaunchAtLoginChangeRequested: @escaping (Bool) -> Void,
         onExit: @escaping () -> Void) {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.userDefaults = userDefaults
        self.keyboardShortcutPreferences = keyboardShortcutPreferences
        self.isLaunchAtLoginAvailable = isLaunchAtLoginAvailable
        self.isLaunchAtLoginEnabled = isLaunchAtLoginEnabled
        self.onModifierShortcutChangeRequested = onModifierShortcutChangeRequested
        self.onTapDurationChangeRequested = onTapDurationChangeRequested
        self.onKeyboardSwitchingStatusRequested = onKeyboardSwitchingStatusRequested
        self.onResumeKeyboardSwitching = onResumeKeyboardSwitching
        self.onLaunchAtLoginChangeRequested = onLaunchAtLoginChangeRequested
        self.onExit = onExit

        super.init()

        configureStatusBarItem()
        applyStoredVisibility()
    }

    func showIcon() {
        userDefaults.set(false, forKey: Self.hideStatusBarIconKey)
        statusBarItem.isVisible = true
    }

    func hideIcon() {
        statusBarItem.isVisible = false
        userDefaults.set(true, forKey: Self.hideStatusBarIconKey)
    }

    private func configureStatusBarItem() {
        statusBarItem.button?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        statusBarItem.isVisible = true
        statusBarItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        menuEntries().enumerated().forEach { index, entry in
            let item = NSMenuItem(title: entry.title,
                                  action: entry.action,
                                  keyEquivalent: entry.keyEquivalent)
            item.target = self
            menu.addItem(item)

            if index == 0 {
                let resumeItem = NSMenuItem(title: "Resume Keyboard Switching…",
                                            action: #selector(resumeKeyboardSwitching), keyEquivalent: "")
                resumeItem.identifier = Self.resumeItemIdentifier
                resumeItem.target = self
                resumeItem.isHidden = true
                menu.addItem(resumeItem)
                menu.addItem(makeModifierShortcutsMenuItem())
                menu.addItem(makeTapDurationMenuItem())
                menu.addItem(makeLaunchAtLoginMenuItem())
            }
        }
        return menu
    }

    private func menuEntries() -> [StatusBarMenuEntry] {
        return [
            StatusBarMenuEntry(title: "About LangSwitch", action: #selector(showAbout)),
            StatusBarMenuEntry(title: "Hide Menu Bar Icon", action: #selector(hideIconAction)),
            StatusBarMenuEntry(title: "Quit LangSwitch", action: #selector(exitAction))
        ]
    }

    private func makeModifierShortcutsMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Modifier Shortcuts", action: nil, keyEquivalent: "")
        item.identifier = Self.modifierShortcutsItemIdentifier

        let submenu = NSMenu()
        let hintItem = NSMenuItem(title: "Select keys that switch language", action: nil, keyEquivalent: "")
        hintItem.isEnabled = false
        submenu.addItem(hintItem)
        submenu.addItem(.separator())

        KeyboardModifierShortcut.allCases.forEach { shortcut in
            let shortcutItem = NSMenuItem(title: shortcut.title,
                                          action: #selector(toggleModifierShortcut(_:)),
                                          keyEquivalent: "")
            shortcutItem.target = self
            shortcutItem.representedObject = shortcut.rawValue
            shortcutItem.state = keyboardShortcutPreferences.isEnabled(shortcut) ? .on : .off
            submenu.addItem(shortcutItem)
        }

        item.submenu = submenu
        return item
    }

    private func makeTapDurationMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.identifier = Self.tapDurationItemIdentifier
        item.toolTip = "Maximum press duration for Fn/Globe and Command. Switching happens when you release the key."
        let submenu = NSMenu()
        for duration in KeyboardShortcutPreferences.tapDurationOptions {
            let title = String(format: "%.1f s", duration)
                + (duration == KeyboardShortcutPreferences.defaultTapDuration ? " (Default)" : "")
            let option = NSMenuItem(title: title, action: #selector(selectTapDuration(_:)), keyEquivalent: "")
            option.target = self
            option.representedObject = duration
            submenu.addItem(option)
        }
        item.submenu = submenu
        updateTapDurationItem(item)
        return item
    }

    private func updateTapDurationItem(_ item: NSMenuItem?) {
        guard let item else { return }
        let selected = keyboardShortcutPreferences.maximumTapDuration
        item.title = String(format: "Maximum Tap Duration: %.1f s", selected)
        item.submenu?.items.forEach { option in
            option.state = (option.representedObject as? TimeInterval) == selected ? .on : .off
        }
    }

    @objc private func selectTapDuration(_ sender: NSMenuItem) {
        guard let duration = sender.representedObject as? TimeInterval else { return }
        onTapDurationChangeRequested(duration)
        updateTapDurationItem(statusBarItem.menu?.items.first { $0.identifier == Self.tapDurationItemIdentifier })
    }

    private func makeLaunchAtLoginMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Launch at Login",
                              action: #selector(toggleLaunchAtLogin(_:)),
                              keyEquivalent: "")
        item.identifier = Self.launchAtLoginItemIdentifier
        item.target = self
        updateLaunchAtLoginItem(item)
        return item
    }

    private func updateModifierShortcutItems(in menu: NSMenu?) {
        menu?.items.forEach { item in
            guard let rawValue = item.representedObject as? String,
                  let shortcut = KeyboardModifierShortcut(rawValue: rawValue) else {
                return
            }

            item.state = keyboardShortcutPreferences.isEnabled(shortcut) ? .on : .off
        }
    }

    private func updateLaunchAtLoginItem(_ item: NSMenuItem?) {
        guard let item else {
            return
        }

        item.isEnabled = isLaunchAtLoginAvailable()
        item.state = isLaunchAtLoginEnabled() ? .on : .off
    }

    private func applyStoredVisibility() {
        statusBarItem.isVisible = !userDefaults.bool(forKey: Self.hideStatusBarIconKey)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let isPaused = onKeyboardSwitchingStatusRequested()
        menu.items.first { $0.identifier == Self.resumeItemIdentifier }?.isHidden = !isPaused
        menu.items.first { $0.identifier == Self.modifierShortcutsItemIdentifier }?.title =
            isPaused ? "Modifier Shortcuts (Paused)" : "Modifier Shortcuts"
        updateModifierShortcutItems(
            in: menu.items.first { $0.identifier == Self.modifierShortcutsItemIdentifier }?.submenu
        )
        updateTapDurationItem(menu.items.first { $0.identifier == Self.tapDurationItemIdentifier })
        updateLaunchAtLoginItem(menu.items.first { $0.identifier == Self.launchAtLoginItemIdentifier })
    }

    @objc private func resumeKeyboardSwitching() {
        onResumeKeyboardSwitching()
    }

    @objc private func showAbout() {
        aboutWindowController.showWindow()
    }

    @objc private func toggleModifierShortcut(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let shortcut = KeyboardModifierShortcut(rawValue: rawValue) else {
            return
        }

        let isEnabled = !keyboardShortcutPreferences.isEnabled(shortcut)
        onModifierShortcutChangeRequested(shortcut, isEnabled)
        updateModifierShortcutItems(in: sender.menu)
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let isEnabled = sender.state != .on
        onLaunchAtLoginChangeRequested(isEnabled)
        updateLaunchAtLoginItem(sender)
    }

    @objc private func hideIconAction() {
        let alert = NSAlert()
        alert.messageText = "The menu bar icon will be hidden."
        alert.informativeText = "To show the icon again, open LangSwitch while it is still running."
        alert.addButton(withTitle: "OK")
        alert.runModal()

        hideIcon()
    }

    @objc private func exitAction() {
        onExit()
    }
}

private struct StatusBarMenuEntry {
    let title: String
    let action: Selector
    let keyEquivalent: String

    init(title: String, action: Selector, keyEquivalent: String = "") {
        self.title = title
        self.action = action
        self.keyEquivalent = keyEquivalent
    }
}
