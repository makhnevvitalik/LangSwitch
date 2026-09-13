//
//  KeyboardSwitchTrigger.swift
//  LangSwitch
//
//  Created by Vitalik Makhnev on 11.06.2026.
//

import AppKit

protocol KeyboardSwitchTrigger {
    mutating func handle(_ event: NSEvent) -> Bool
}
