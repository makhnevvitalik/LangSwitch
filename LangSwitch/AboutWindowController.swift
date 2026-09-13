//
//  AboutWindowController.swift
//  LangSwitch
//
//  Created by Vitalik Makhnev on 11.06.2026.
//

import AppKit
import Foundation

final class AboutWindowController: NSObject {
    private var aboutWindow: NSWindow?
    private var checkUpdatesButton: NSButton?
    private var isCheckingForUpdates = false

    func showWindow() {
        if aboutWindow == nil {
            aboutWindow = makeAboutWindow()
        }

        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var versionTitle: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown version"
        return "LangSwitch v\(version)"
    }

    private func makeAboutWindow() -> NSWindow {
        let windowWidth: CGFloat = 320
        let windowHeight: CGFloat = 180

        let windowContent = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))

        let versionLabel = NSTextField(labelWithString: versionTitle)
        versionLabel.frame = NSRect(x: (windowWidth - 240) / 2, y: 130, width: 240, height: 22)
        versionLabel.alignment = .center
        windowContent.addSubview(versionLabel)

        let gitHubButton = NSButton(title: "GitHub Page", target: self, action: #selector(openGitHub))
        gitHubButton.frame = NSRect(x: (windowWidth - 130) / 2, y: 90, width: 130, height: 32)
        windowContent.addSubview(gitHubButton)

        let checkUpdatesButton = NSButton(title: "Check for Updates", target: self, action: #selector(checkForUpdates))
        checkUpdatesButton.frame = NSRect(x: (windowWidth - 170) / 2, y: 44, width: 170, height: 32)
        windowContent.addSubview(checkUpdatesButton)
        self.checkUpdatesButton = checkUpdatesButton

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = windowContent
        window.center()

        return window
    }

    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/makhnevvitalik/LangSwitch") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func checkForUpdates() {
        guard !isCheckingForUpdates,
              let url = URL(string: "https://api.github.com/repos/makhnevvitalik/LangSwitch/releases/latest") else {
            return
        }

        isCheckingForUpdates = true
        checkUpdatesButton?.isEnabled = false

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }

                defer {
                    self.isCheckingForUpdates = false
                    self.checkUpdatesButton?.isEnabled = true
                }

                let alert = NSAlert()
                alert.messageText = self.updateCheckMessage(data: data, response: response, error: error)
                alert.runModal()
            }
        }
        task.resume()
    }

    private func updateCheckMessage(data: Data?, response: URLResponse?, error: Error?) -> String {
        if error != nil {
            return "Could not contact GitHub. Please try again."
        }

        guard let response = response as? HTTPURLResponse else {
            return "GitHub returned an invalid response. Please try again later."
        }

        guard (200...299).contains(response.statusCode) else {
            return "GitHub returned HTTP \(response.statusCode). Please try again later."
        }

        guard let data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let latestVersionTag = json["tag_name"] as? String,
              let latestVersion = AppVersion(latestVersionTag) else {
            return "GitHub returned invalid update information. Please try again later."
        }

        guard let currentVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let currentVersion = AppVersion(currentVersionString) else {
            return "Could not determine the installed app version."
        }

        if latestVersion > currentVersion {
            return "New version \(latestVersionTag) is available! Download it from GitHub."
        }

        return "You're up to date."
    }
}

private struct AppVersion: Comparable {
    private let components: [Int]

    init?(_ rawValue: String) {
        var normalizedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedValue.lowercased().hasPrefix("v") {
            normalizedValue.removeFirst()
        }

        let components = normalizedValue.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard !components.isEmpty else {
            return nil
        }

        var parsedComponents = [Int]()
        for component in components {
            guard !component.isEmpty,
                  let parsedComponent = Int(component),
                  parsedComponent >= 0 else {
                return nil
            }

            parsedComponents.append(parsedComponent)
        }

        self.components = parsedComponents
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let componentCount = max(lhs.components.count, rhs.components.count)
        for index in 0..<componentCount {
            let leftComponent = lhs.component(at: index)
            let rightComponent = rhs.component(at: index)

            if leftComponent != rightComponent {
                return leftComponent < rightComponent
            }
        }

        return false
    }

    private func component(at index: Int) -> Int {
        guard index < components.count else {
            return 0
        }

        return components[index]
    }
}
