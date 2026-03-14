# Pomdoro — Design Spec

## Overview

A native macOS menu bar app with two independent timers, styled to look like a physical dual-timer device with seven-segment LCD displays. Built with pure SwiftUI using Swift 6 best practices.

## Platform & Requirements

- **Platform:** macOS only
- **Minimum OS:** macOS 13 Ventura
- **Language:** Swift 6 with strict concurrency
- **UI Framework:** Pure SwiftUI
- **Architecture:** `@Observable` macro, SwiftUI App lifecycle, no AppDelegate

## Visual Design

### Style
Skeuomorphic LCD aesthetic — dark background, seven-segment digit shapes rendered as custom SwiftUI `Shape` paths. Active segments glow in a user-configurable color (default: white). Inactive segments rendered at ~5% opacity to simulate visible "off" segments on a real LCD.

### Layout
Two timer panels stacked vertically, each containing:
- A mode arrow (`▼` countdown / `▲` timer) in the top-left corner — clickable to toggle
- `T1` / `T2` label in the top-right corner
- Seven-segment `MM:SS` display
- `M` and `S` labels below the digit pairs
- Start (green ▶) and Stop (red ■) buttons stacked vertically to the right of the panel

A chain link button sits between the two panels.

A settings gear icon sits in the bottom-right corner.

### Window Sizes
Four fixed sizes that proportionally scale all UI elements (digits, buttons, spacing):

| Size   | Width  |
|--------|--------|
| Small  | ~280px |
| Medium | ~360px |
| Large  | ~460px |
| XL     | ~580px |

Heights scale proportionally. No free resizing — user picks a size from settings or a menu.

## App Shell

### Menu Bar
- `MenuBarExtra` with `.window` style
- Menu bar icon: timer/clock SF Symbol; shows remaining time as text when a timer is running (e.g., "24:31")
- Clicking the icon shows the timer panel

### Detachable Window
- The `MenuBarExtra` window can be detached into a floating window
- Floating window stays on top of other windows
- Compact, matching the physical timer's proportions

## Timer Behavior

### Modes (per timer)
- **Countdown (▼):** Set a target time, counts down to 00:00
- **Timer (▲):** Starts at 00:00, counts up (stopwatch)
- Toggle by clicking the arrow indicator in the top-left of each panel

### Unchained (default)
- Each timer operates independently
- Each timer has its own Start/Stop buttons to the right
- Both can run simultaneously

### Chained
- Chain link button between panels toggles chaining on/off
- When chained: only T1's Start/Stop buttons are shown
- Starting begins T1 countdown; when T1 hits 00:00, a short beep plays and T2 auto-starts
- When T2 hits 00:00, the full alarm sounds
- Chain link icon: SF Symbol `link` (chained, highlighted amber) / `link.slash` (unchained, dimmed)
- Subtle animation on toggle

## Time Input

### Click to select
- Click on a digit pair (minutes or seconds) to select it
- A subtle highlight box appears around the selected digit pair
- Arrow keys (up/down) increment/decrement the selected value
- Type a number directly to set the value
- Click elsewhere, Enter, or Escape to deselect

### Keyboard shortcuts (when app window is focused)
- `Space` — start/pause
- `R` — reset
- `1` / `2` — select Timer 1 / Timer 2
- `Tab` — toggle between minute/second digit selection
- `Up/Down` — adjust selected digits
- `Enter/Esc` — confirm/cancel digit editing

## Notifications & Sound

### Alerts
- **T1 completion (chained):** Short beep + macOS notification banner ("Timer 1 complete — Timer 2 started")
- **T2 / standalone completion:** Full alarm sound + notification banner ("Timer complete!")
- Alarm continues until user clicks the app or presses any key

### Sound system
- `AVAudioPlayer` for bundled custom sounds
- `NSSound` for system sounds
- Ships with good default sounds (short beep for transition, proper alarm for completion)
- User can select from bundled sounds or system sounds in settings

## Settings

Accessed via gear icon or `Cmd+,`:
- **Digit color:** Preset swatches (white, green, amber, red, blue) + custom `ColorPicker`
- **Sound selection:** Dropdowns for T1 transition beep and T2/completion alarm, with preview buttons
- **Default times:** Set default T1 and T2 values that persist across launches
- **Window size:** Small / Medium / Large / XL

### Persistence
- `@AppStorage` for all settings (digit color, sounds, default times, window size)
- Timer state does not persist across app launches

## Core Types

### `TimerModel` (`@Observable`)
State for a single timer: remaining/elapsed time, target time, mode (countdown/timer), running state. Ticks via `TimelineView` or `Timer.publish`.

### `PomodoroManager` (`@Observable`)
Owns two `TimerModel` instances + chaining toggle. Handles T1→T2 transition logic and alarm triggering.

### `SoundManager`
Plays notification sounds (short beep vs full alarm), manages user sound preferences.

### `SettingsModel`
Wraps `@AppStorage` values for digit color, selected sounds, default times, window size.

## View Hierarchy

```
PomodoroApp (MenuBarExtra)
 └── MainTimerView
      ├── TimerPanelView (Timer 1)
      │    ├── ModeArrow
      │    ├── SevenSegmentDisplay
      │    └── TimerControls (start/stop)
      ├── ChainLinkButton
      ├── TimerPanelView (Timer 2)
      │    ├── ModeArrow
      │    ├── SevenSegmentDisplay
      │    └── TimerControls (start/stop, hidden when chained)
      ├── SettingsButton
      └── SettingsView (sheet/window)
