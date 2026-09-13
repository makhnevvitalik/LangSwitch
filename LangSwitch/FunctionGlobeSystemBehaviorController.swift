//
//  FunctionGlobeSystemBehaviorController.swift
//  LangSwitch
//
//  Created by Vitalik Makhnev on 15.06.2026.
//

import AppKit
import Foundation

final class FunctionGlobeSystemBehaviorController {
    enum TrackingAvailability {
        case available
        case unavailable(String)
    }

    private enum Constants {
        static let domain = "com.apple.HIToolbox" as CFString
        static let usageTypeKey = "AppleFnUsageType" as CFString
        static let doNothingUsageType = 0
        static let keyboardSettingsURLs = [
            "x-apple.systempreferences:com.apple.Keyboard-Settings.extension",
            "x-apple.systempreferences:com.apple.preference.keyboard",
            "x-apple.systempreferences:"
        ]
    }

    func trackingAvailability() -> TrackingAvailability {
        guard let currentUsageType = readUsageType() else {
            return .unavailable("LangSwitch could not read the current Fn/Globe system setting. In System Settings > Keyboard, set Fn/Globe key action to Do Nothing, then enable Fn/Globe in LangSwitch again.")
        }

        guard currentUsageType == Constants.doNothingUsageType else {
            return .unavailable("macOS is using the Fn/Globe key for a system action. In System Settings > Keyboard, set Fn/Globe key action to Do Nothing, then enable Fn/Globe in LangSwitch again.")
        }

        return .available
    }

    @discardableResult
    func openKeyboardSettings() -> Bool {
        for urlString in Constants.keyboardSettingsURLs {
            guard let url = URL(string: urlString) else {
                continue
            }

            if NSWorkspace.shared.open(url) {
                return true
            }
        }

        print("Failed to open Keyboard settings.")
        return false
    }

    private func readUsageType() -> Int? {
        guard let value = CFPreferencesCopyAppValue(Constants.usageTypeKey, Constants.domain) else {
            return nil
        }

        if let usageType = value as? Int {
            return usageType
        }

        if let usageType = value as? NSNumber {
            return usageType.intValue
        }

        return nil
    }
}
