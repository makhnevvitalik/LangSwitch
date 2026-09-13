//
//  KeyboardShortcutPreferences.swift
//  LangSwitch
//
//  Created by Vitalik Makhnev on 11.06.2026.
//

import AppKit
import Foundation

enum KeyboardModifierShortcut: String, CaseIterable {
    case functionGlobe
    case command

    var title: String {
        switch self {
        case .functionGlobe:
            return "Fn/Globe"
        case .command:
            return "Command"
        }
    }

    var userDefaultsKey: String {
        switch self {
        case .functionGlobe:
            return "keyboardShortcut.functionGlobe.enabled"
        case .command:
            return "keyboardShortcut.command.enabled"
        }
    }

    var isEnabledByDefault: Bool {
        switch self {
        case .functionGlobe:
            return false
        case .command:
            return false
        }
    }

    func makeTrigger(longPressThreshold: TimeInterval) -> any KeyboardSwitchTrigger {
        switch self {
        case .functionGlobe:
            return StandaloneModifierTapTracker.functionGlobe(longPressThreshold: longPressThreshold)
        case .command:
            return StandaloneModifierTapTracker.command(longPressThreshold: longPressThreshold)
        }
    }
}

final class KeyboardShortcutPreferences {
    static let tapDurationOptions: [TimeInterval] = (1...10).map { Double($0) / 10 }
    static let defaultTapDuration: TimeInterval = 0.2
    private static let tapDurationKey = "keyboardShortcut.maximumTapDuration"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var maximumTapDuration: TimeInterval {
        get {
            let value = userDefaults.double(forKey: Self.tapDurationKey)
            return Self.tapDurationOptions.contains(value) ? value : Self.defaultTapDuration
        }
        set {
            guard Self.tapDurationOptions.contains(newValue) else { return }
            userDefaults.set(newValue, forKey: Self.tapDurationKey)
        }
    }

    var enabledShortcuts: [KeyboardModifierShortcut] {
        KeyboardModifierShortcut.allCases.filter { isEnabled($0) }
    }

    func isEnabled(_ shortcut: KeyboardModifierShortcut) -> Bool {
        guard userDefaults.object(forKey: shortcut.userDefaultsKey) != nil else {
            return shortcut.isEnabledByDefault
        }

        return userDefaults.bool(forKey: shortcut.userDefaultsKey)
    }

    func setEnabled(_ isEnabled: Bool, for shortcut: KeyboardModifierShortcut) {
        userDefaults.set(isEnabled, forKey: shortcut.userDefaultsKey)
    }
}
