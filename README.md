# LangSwitch

LangSwitch is a lightweight macOS menu bar app that cycles through your keyboard languages (input sources) with a quick tap of Fn/🌐 or Command (⌘), without the system language-switching popup.

## Features

- **Choose your switching keys.** Enable Fn/Globe, Command, or both from the **Modifier Shortcuts** menu. Command switching supports either the left or right Command key.
- **Adjust tap duration.** Choose a maximum tap duration from 0.1 to 1.0 seconds. The default is 0.2 seconds.
- **Launch at login.** On macOS 13 or later, enable **Launch at Login** to start LangSwitch when you sign in.
- **Hide the menu bar icon.** Choose **Hide Menu Bar Icon** to keep LangSwitch running in the background. Open LangSwitch again while it is running to restore the icon.

## Quick start

1. Download the ZIP from the [latest release](https://github.com/makhnevvitalik/LangSwitch/releases/latest), unzip it, and move **LangSwitch.app** to **Applications**. Open the app; if macOS blocks it, follow the [first-launch steps](#first-launch-allow-langswitch-in-macos) below.
2. Click the globe icon in the menu bar and open **Modifier Shortcuts**. Both switching options are off by default; enable the one or ones you want to use.
3. Allow Input Monitoring when prompted, using the steps below.
4. If you use Fn/Globe, set its macOS action to **Do Nothing** as described below.
5. Briefly tap and release the selected key to switch to the next input source.

### First launch: allow LangSwitch in macOS

The downloadable app is not signed with an Apple Developer ID certificate and is not notarized by Apple, so macOS may block it on first launch. If you downloaded it from this repository and trust it, allow it using these steps:

1. Try opening **LangSwitch.app** from **Applications** once. If macOS blocks it because the developer cannot be verified or Apple cannot check the app, dismiss the warning without moving the app to Trash.
2. Open **Apple menu → System Settings → Privacy & Security** and scroll down to **Security**.
3. Find the message about LangSwitch being blocked and click **Open Anyway**. If your macOS version shows **Open** first, click it, then **Open Anyway**.
4. Confirm that you want to open the app and enter your Mac login password if prompted.

The approval is saved, so you can open the app normally afterward. The **Open Anyway** button is available for about an hour after a blocked launch attempt; if it is missing, try opening LangSwitch again, then return to settings. See [Apple's instructions](https://support.apple.com/guide/mac-help/mh40616/mac).

On **macOS 11–12**, use **System Preferences → Security & Privacy → General → Open Anyway** instead. See [Apple's instructions for older macOS versions](https://support.apple.com/guide/mac-help/mh40616/12.0/mac/12.0).

### Allow Input Monitoring

Fn/Globe and Command switching both require Input Monitoring access. When LangSwitch shows **Keyboard switching is paused**, use the matching button and enable LangSwitch here:

- **macOS 13 or later:** click **Grant Access** or **Open System Settings**, then open **System Settings → Privacy & Security → Input Monitoring**.
- **macOS 11–12:** click **Grant Access** or **Open System Preferences**, then open **System Preferences → Security & Privacy → Privacy → Input Monitoring**.

Your selected keys remain saved while access is unavailable. Return to LangSwitch after enabling access; switching resumes automatically. If macOS asks, choose **Quit & Reopen**. If the menu still shows **Modifier Shortcuts (Paused)**, choose **Resume Keyboard Switching… → Restart LangSwitch**.

Use **Maximum Tap Duration** in the LangSwitch menu to choose how quickly you must release the key. Available values are 0.1–1.0 seconds; the default is 0.2 seconds.

### Fn/Globe

Set the Fn/Globe key action to **Do Nothing**, then enable **Modifier Shortcuts → Fn/Globe** in LangSwitch:

- **macOS 13 or later:** open **System Settings → Keyboard**.
- **macOS 11–12:** open **System Preferences → Keyboard**.

If macOS is using the key for a system action, or LangSwitch cannot read its setting, LangSwitch keeps this option off and offers to open Keyboard settings.

### Command

After allowing Input Monitoring, Command does not require any additional system setting.

## License

New versions of LangSwitch are licensed under the MIT License + Commons Clause
License Condition v1.0. This means the MIT License is subject to the Commons
Clause: you may use, study, modify, and redistribute the source code, but you
may not sell LangSwitch itself or a product/service whose value derives entirely
or substantially from LangSwitch.

Earlier versions that were already published under the MIT License remain
available under those MIT terms. Original and third-party notices are preserved
in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

LangSwitch is source-available, but it is not OSI open source under the current
license.
