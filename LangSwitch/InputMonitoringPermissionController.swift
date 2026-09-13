import AppKit
import CoreGraphics

final class InputMonitoringPermissionController {
    private var hasRequestedAccess = false

    private var inputMonitoringSettingsPath: String {
        if #available(macOS 13.0, *) {
            return "System Settings > Privacy & Security > Input Monitoring"
        }

        return "System Preferences > Security & Privacy > Privacy > Input Monitoring"
    }

    private var settingsButtonTitle: String {
        if #available(macOS 13.0, *) {
            return "Open System Settings"
        }

        return "Open System Preferences"
    }

    private var isAllowed: Bool {
        CGPreflightListenEventAccess()
    }

    func showRecoveryOptions(onRestart: () -> Void) {
        let shouldRequestAccess = !isAllowed && !hasRequestedAccess
        let alert = NSAlert()
        alert.messageText = "Keyboard switching is paused."
        alert.informativeText = "Allow LangSwitch in \(inputMonitoringSettingsPath). Your selected keys are saved. Return to LangSwitch after allowing access; switching will resume automatically. If macOS asks, choose Quit & Reopen. If switching remains paused, restart LangSwitch."
        alert.addButton(withTitle: shouldRequestAccess ? "Grant Access" : settingsButtonTitle)
        alert.addButton(withTitle: "Restart LangSwitch")
        alert.addButton(withTitle: "Later")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            if shouldRequestAccess {
                hasRequestedAccess = true
                // Let the system prompt open Settings; opening them here too
                // would show both windows at the same time.
                CGRequestListenEventAccess()
            } else if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                NSWorkspace.shared.open(url)
            }
        case .alertSecondButtonReturn:
            onRestart()
        default:
            break
        }
    }
}
