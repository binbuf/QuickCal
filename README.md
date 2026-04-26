# QuickCal

A macOS menu bar app that replaces the system clock with a Windows 11-style calendar flyout — click the time to get a full month calendar with your agenda. Built with SwiftUI and AppKit, targeting macOS 26 (Tahoe).

## Prerequisites

- macOS 26+
- Xcode 26+
- [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build & Run

```bash
make run        # generate project, build debug, launch
```

Or step by step:

```bash
make generate   # create .xcodeproj from project.yml
make build      # debug build
make release    # release build → ./build/Build/Products/Release/QuickCal.app
```

> **Note:** If `xcode-select -p` points to CommandLineTools instead of Xcode.app, the Makefile handles this automatically via `DEVELOPER_DIR`. To fix globally: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

## First Launch

1. QuickCal opens an onboarding window explaining the Accessibility permission requirement
2. Click **Open Accessibility Settings** → toggle QuickCal on in System Settings
3. The onboarding window detects the permission and shows **Get Started**
4. QuickCal installs its clock in the menu bar, overlays the system clock, and is ready to use

## Usage

- **Left-click** the menu bar clock → opens the calendar flyout
- **Right-click** → context menu (Launch at Login, Uninstall, Quit)
- **Arrow keys** navigate the calendar grid, **Escape** closes the flyout
- Click the month/year header to zoom out (Day → Month → Decade), click a cell to zoom back in

## Uninstall

From the app: right-click the clock → **Uninstall QuickCal**

From the DMG: double-click `Scripts/uninstall-quickcal.command`

Both methods remove the overlay, login item, Accessibility permission, and all preferences.

## Credits

App icon: [Calendar icon](https://www.flaticon.com/free-icon/calendar_3842121) by Flaticon.

## Project Structure

```
QuickCal/
  App/          @main entry, AppDelegate, shared state
  Onboarding/   Accessibility permission flow
  Clock/        Status item, clock prefs, AXUIElement overlay
  Calendar/     Flyout panel, month grid, zoom views, agenda
  EventKit/     Calendar event fetching
  AutoStart/    SMAppService login item
  Uninstaller/  In-app + script-based removal
```
