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
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
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
