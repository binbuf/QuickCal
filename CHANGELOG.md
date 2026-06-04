# Changelog

All notable changes to QuickCal are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-06-04

### Added
- **Launch-at-login onboarding step** — after picking a clock mode, onboarding now
  offers to start QuickCal automatically at login (changeable later from the
  right-click menu).
- **Live Analog Companion setup** — onboarding shows a live preview of QuickCal's
  menu-bar readout and detects in real time whether the macOS clock is already set
  to Analog, confirming when you're all set or warning that you'll otherwise see two
  clocks.
- **"Open Clock Settings" shortcut** — the right-click analog tip now deep-links
  straight to Control Center → Clock settings, and is suppressed when the macOS clock
  is already analog.
- `SystemClockState` helper that reads the live macOS menu-bar clock style and
  centralizes the "switch to Analog" guidance.

### Changed
- **Wall-clock-aligned ticking** — both the menu-bar clock and the flyout header now
  update on whole/half-second boundaries instead of drifting from launch time, keeping
  the displayed time in lock-step with the OS clock.
- The blinking separator (flashing colon) now toggles precisely on the half-second
  boundary.
- Reordered the onboarding mode cards to lead with Calendar Icon, followed by Analog
  Companion.
- Rewrote and trimmed the README; the screenshot is now bundled in-repo
  (`docs/app.png`).
- Refer to "Apple Silicon" rather than "arm64" in release wording.

### Fixed
- **Weekday header** — the duplicate single-letter columns (Thursday's "T" and
  Saturday's "S") were silently dropped; all seven day letters now render.
- **Flyout corners** — the popover's behind-window material no longer bleeds square
  corners; it's clipped to a clean rounded mask.

## [0.1.0]

### Added
- Initial release: click the macOS menu-bar clock to get a calendar flyout.
- Month grid with today highlighted and event dots on days with events.
- Click-to-zoom navigation: Month → Decade → back.
- Agenda strip showing the day's events pulled from Apple Calendar.
- Two menu-bar modes — Analog Companion (digital readout alongside the macOS analog
  clock) and Calendar Icon.
- First-run onboarding and an uninstaller.

[0.2.0]: https://github.com/binbuf/QuickCal/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/binbuf/QuickCal/releases/tag/v0.1.0
