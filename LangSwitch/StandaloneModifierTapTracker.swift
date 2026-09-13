//
//  StandaloneModifierTapTracker.swift
//  LangSwitch
//
//  Created by Vitalik Makhnev on 11.06.2026.
//

import AppKit
import Foundation

struct StandaloneModifierTapTracker: KeyboardSwitchTrigger {
    private static let functionGlobeKeyCode: UInt16 = 63
    private static let rightCommandKeyCode: UInt16 = 54
    private static let leftCommandKeyCode: UInt16 = 55

    private let keyCodes: Set<UInt16>
    private let modifierFlag: NSEvent.ModifierFlags
    private let allowedAdditionalFlags: NSEvent.ModifierFlags
    private let longPressThreshold: TimeInterval
    private var pressedKeyCodes = Set<UInt16>()
    private var pressStartedAt: TimeInterval?
    private var usedWithAnotherKey = false

    init(keyCodes: Set<UInt16>,
         modifierFlag: NSEvent.ModifierFlags,
         allowedAdditionalFlags: NSEvent.ModifierFlags = [.capsLock],
         longPressThreshold: TimeInterval) {
        self.keyCodes = keyCodes
        self.modifierFlag = modifierFlag
        self.allowedAdditionalFlags = allowedAdditionalFlags
        self.longPressThreshold = longPressThreshold
    }

    static func functionGlobe(longPressThreshold: TimeInterval) -> Self {
        Self(keyCodes: [functionGlobeKeyCode],
             modifierFlag: .function,
             longPressThreshold: longPressThreshold)
    }

    static func command(longPressThreshold: TimeInterval) -> Self {
        Self(keyCodes: [leftCommandKeyCode, rightCommandKeyCode],
             modifierFlag: .command,
             longPressThreshold: longPressThreshold)
    }

    mutating func handle(_ event: NSEvent) -> Bool {
        switch event.type {
        case .flagsChanged:
            return flagsChanged(keyCode: event.keyCode,
                                modifierFlags: event.modifierFlags,
                                timestamp: event.timestamp)
        case .keyDown:
            markUsedInCombination(modifierFlags: event.modifierFlags)
            return false
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            if modifierFlag == .command {
                markUsedInCombination(modifierFlags: event.modifierFlags)
            }
            return false
        default:
            return false
        }
    }

    private mutating func flagsChanged(keyCode: UInt16,
                                       modifierFlags: NSEvent.ModifierFlags,
                                       timestamp: TimeInterval) -> Bool {
        let flags = modifierFlags.intersection(.deviceIndependentFlagsMask)

        guard keyCodes.contains(keyCode) else {
            if !pressedKeyCodes.isEmpty && containsDisallowedFlags(flags) {
                usedWithAnotherKey = true
            }
            return false
        }

        guard flags.contains(modifierFlag) else {
            pressedKeyCodes.removeAll()
            return finishIfNeeded(timestamp: timestamp, flags: flags)
        }

        if pressedKeyCodes.isEmpty {
            pressStartedAt = timestamp
            usedWithAnotherKey = false
        } else if !pressedKeyCodes.contains(keyCode) {
            usedWithAnotherKey = true
        }

        pressedKeyCodes.insert(keyCode)

        if containsDisallowedFlags(flags) {
            usedWithAnotherKey = true
        }

        return false
    }

    private mutating func markUsedInCombination(modifierFlags: NSEvent.ModifierFlags) {
        guard !pressedKeyCodes.isEmpty else {
            return
        }

        let flags = modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(modifierFlag) {
            usedWithAnotherKey = true
        }
    }

    private mutating func finishIfNeeded(timestamp: TimeInterval, flags: NSEvent.ModifierFlags) -> Bool {
        guard pressedKeyCodes.isEmpty else {
            return false
        }

        defer {
            pressStartedAt = nil
            usedWithAnotherKey = false
        }

        guard let pressStartedAt else {
            return false
        }

        return !usedWithAnotherKey
            && !containsDisallowedFlags(flags)
            && timestamp - pressStartedAt < longPressThreshold
    }

    private func containsDisallowedFlags(_ flags: NSEvent.ModifierFlags) -> Bool {
        let allowedFlags = allowedAdditionalFlags.union(modifierFlag)
        return !flags.subtracting(allowedFlags).isEmpty
    }
}
