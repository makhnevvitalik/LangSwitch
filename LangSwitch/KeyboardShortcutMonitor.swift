import AppKit
import CoreGraphics

final class KeyboardShortcutMonitor {
    private let shortcuts: [KeyboardModifierShortcut]
    private let longPressThreshold: TimeInterval
    private let onTrigger: () -> Void
    private let onUnavailable: () -> Void
    private var trackers: [any KeyboardSwitchTrigger]
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(shortcuts: [KeyboardModifierShortcut],
         longPressThreshold: TimeInterval,
         onTrigger: @escaping () -> Void,
         onUnavailable: @escaping () -> Void) {
        self.shortcuts = shortcuts
        self.longPressThreshold = longPressThreshold
        self.onTrigger = onTrigger
        self.onUnavailable = onUnavailable
        self.trackers = shortcuts.map { $0.makeTrigger(longPressThreshold: longPressThreshold) }
    }

    var isRunning: Bool {
        guard let eventTap, CFMachPortIsValid(eventTap) else { return false }
        return CGEvent.tapIsEnabled(tap: eventTap)
    }

    @discardableResult
    func start() -> Bool {
        stop()
        guard !shortcuts.isEmpty, CGPreflightListenEventAccess() else {
            return false
        }

        var eventTypes: [CGEventType] = [.flagsChanged, .keyDown]
        if shortcuts.contains(.command) {
            eventTypes += [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        }
        let mask = eventTypes.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                if let userInfo {
                    let monitor = Unmanaged<KeyboardShortcutMonitor>.fromOpaque(userInfo).takeUnretainedValue()
                    monitor.handle(type: type, event: event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            return false
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        guard CGEvent.tapIsEnabled(tap: tap) else {
            stop()
            return false
        }
        return true
    }

    func stop() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        runLoopSource = nil
        eventTap = nil
        trackers = shortcuts.map { $0.makeTrigger(longPressThreshold: longPressThreshold) }
    }

    deinit {
        stop()
    }

    private func handle(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            trackers = shortcuts.map { $0.makeTrigger(longPressThreshold: longPressThreshold) }
            if let eventTap, CGPreflightListenEventAccess() {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                if CGEvent.tapIsEnabled(tap: eventTap) {
                    return
                }
            }
            stop()
            DispatchQueue.main.async { [weak self] in
                self?.onUnavailable()
            }
            return
        }

        if processEvent(event) {
            // Keep the event callback short; switch the input source after returning it.
            DispatchQueue.main.async { [weak self] in
                guard let self, self.eventTap != nil else { return }
                self.onTrigger()
            }
        }
    }

    private func processEvent(_ event: CGEvent) -> Bool {
        guard let keyboardEvent = NSEvent(cgEvent: event) else {
            return false
        }
        var shouldSwitch = false
        for index in trackers.indices {
            if trackers[index].handle(keyboardEvent) {
                shouldSwitch = true
            }
        }
        return shouldSwitch
    }
}
