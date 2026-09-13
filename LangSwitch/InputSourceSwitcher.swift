//
//  InputSourceSwitcher.swift
//  LangSwitch
//
//  Created by Vitalik Makhnev on 11.06.2026.
//

import Carbon
import Foundation

final class InputSourceSwitcher {
    func switchToNextInputSource() {
        guard let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            print("Failed to switch keyboard language.")
            return
        }

        let inputSources = getInputSources()
        guard !inputSources.isEmpty else {
            print("Failed to switch keyboard language.")
            return
        }

        guard let currentIndex = inputSources.firstIndex(where: { $0 == currentSource }) else {
            print("Failed to switch keyboard language.")
            return
        }

        let nextIndex = (currentIndex + 1) % inputSources.count
        let nextSource = inputSources[nextIndex]

        let status = TISSelectInputSource(nextSource)
        guard status == noErr else {
            print("Failed to switch keyboard language. OSStatus: \(status)")
            return
        }

        if let newSourceName = nextSource.localizedName {
            print("Switched to: \(newSourceName)")
        }
    }

    private func getInputSources() -> [TISInputSource] {
        let inputSourceNSArray = TISCreateInputSourceList(nil, false)
            .takeRetainedValue() as NSArray
        let inputSourceList = inputSourceNSArray as! [TISInputSource]

        return inputSourceList.filter {
            $0.category == TISInputSource.Category.keyboardInputSource && $0.isSelectable
        }
    }
}

private extension TISInputSource {
    enum Category {
        static var keyboardInputSource: String {
            return kTISCategoryKeyboardInputSource as String
        }
    }

    func getProperty(_ key: CFString) -> AnyObject? {
        guard let cfType = TISGetInputSourceProperty(self, key) else {
            return nil
        }

        return Unmanaged<AnyObject>.fromOpaque(cfType).takeUnretainedValue()
    }

    var category: String? {
        return getProperty(kTISPropertyInputSourceCategory) as? String
    }

    var isSelectable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as? Bool ?? false
    }

    var localizedName: String? {
        return getProperty(kTISPropertyLocalizedName) as? String
    }
}
