//
//  KeyboardShortcutMonitor.swift
//  LangSwitch
//
//  Created by Vitalik Makhnev on 11.06.2026.
//

import AppKit

final class KeyboardShortcutMonitor {
    private var triggers: [any KeyboardSwitchTrigger]
    private let onTrigger: () -> Void
    private var monitor: Any?

    init(triggers: [any KeyboardSwitchTrigger], onTrigger: @escaping () -> Void) {
        self.triggers = triggers
        self.onTrigger = onTrigger
    }

    func start() {
        stop()

        monitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handle(event)
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        stop()
    }

    private var eventMask: NSEvent.EventTypeMask {
        triggers.reduce([]) { mask, trigger in
            mask.union(trigger.eventMask)
        }
    }

    private func handle(_ event: NSEvent) {
        for index in triggers.indices {
            if triggers[index].handle(event) {
                onTrigger()
                return
            }
        }
    }
}
