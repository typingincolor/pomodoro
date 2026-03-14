# Pomdoro — Design Spec

## Overview

A native macOS menu bar app with two independent timers, styled to look like a physical dual-timer device with seven-segment LCD displays. Built with pure SwiftUI using Swift 6 best practices.

## Platform & Requirements

- **Platform:** macOS only
- **Minimum OS:** macOS 13 Ventura
- **Language:** Swift 6 with strict concurrency
- **UI Framework:** Pure SwiftUI
- **Architecture:** `@Observable` macro, SwiftUI App lifecycle. Uses `NSApplicationDelegateAdaptor` for AppKit bridging (floating panel management).

## Visual Design

### Style
Skeuomorphic LCD aesthetic — dark background, seven-segment digit shapes rendered as custom SwiftUI `Shape` paths. Active segments glow in a user-configurable color (default: white). Inactive segments rendered at ~5% opacity to simulate visible "off" segments on a real LCD.

### Layout
Two timer panels stacked vertically, each containing:
- A mode arrow (`▼` countdown / `▲` timer) in the top-left corner — clickable to toggle
- `T1` / `T2` label in the top-right corner
- Seven-segment `MM:SS` display (max value: 99:59)
- `M` and `S` labels below the digit pairs
- Play/Pause (green ▶ / amber ⏸) and Reset (red ↺) buttons stacked vertically to the right of the panel

A chain link button sits between the two panels.

A settings gear icon sits in the bottom-right corner.

### Window Sizes
Four fixed sizes that proportionally scale all UI elements (digits, buttons, spacing):

| Size   | Width |
|--------|-------|
| Small  | 280pt |
| Medium | 360pt |
| Large  | 460pt |
| XL     | 580pt |

Heights scale proportionally. No free resizing — user picks a size from settings or a menu.

## App Shell

### Menu Bar
- `MenuBarExtra` with `.window` style
- Menu bar icon: SF Symbol `timer` by default; when a single timer is running, shows its remaining/elapsed time as text (e.g., "24:31"). When both timers are running (unchained), shows T1's time.
- Clicking the icon shows the timer panel

### Detachable Window
- A pin/detach button in the `MenuBarExtra` panel opens the timers in a standalone `NSPanel` (`.utilityWindow` style level, floating on top)
- Managed via `NSApplicationDelegateAdaptor` — the app delegate creates/owns the `NSPanel` and hosts the SwiftUI view hierarchy in it
- When the panel is open, the `MenuBarExtra` popover is not shown on click; instead, clicking the menu bar icon brings the panel to front
- The panel has a close button — closing it returns to popover mode
- Panel remembers its last position between detach/re-attach cycles
- Compact, matching the physical timer's proportions

## Timer Behavior

### Modes (per timer)
- **Countdown (▼):** Set a target time, counts down to 00:00
- **Timer (▲):** Starts at 00:00, counts up (stopwatch)
- Toggle by clicking the arrow indicator in the top-left of each panel

### Unchained (default)
- Each timer operates independently
- Each timer has its own Play/Pause and Reset buttons to the right
- Both can run simultaneously

### Chained
- Chain link button between panels toggles chaining on/off
- Chaining forces both timers into countdown mode (▼)
- When chained: only T1's Play/Pause and Reset buttons are shown
- Starting begins T1 countdown; when T1 hits 00:00, a short beep plays and T2 auto-starts
- When T2 hits 00:00, the full alarm sounds
- Pressing Pause during a chained sequence pauses whichever timer is active. Pressing Play resumes the chain from where it left off.
- Pressing Reset during a paused chained sequence resets both timers to their original set values
- Chain link icon: SF Symbol `link` (chained, highlighted amber) / `link.slash` (unchained, dimmed)
- Subtle animation on toggle

### Play/Pause/Reset behavior
- **Play (▶, green):** Begins or resumes the timer. In countdown mode, counts down from the set time (or resumes from where it was paused). In timer mode, counts up from 00:00 (or resumes).
- **Pause (⏸, amber):** Halts the timer in place without resetting. The button toggles back to Play. Shown only while a timer is running.
- **Reset (↺, red):** Resets the timer to its last set value (countdown) or 00:00 (timer mode). Only enabled when the timer is paused or has completed.

## Time Input

### Click to select
- Click on a digit pair (minutes or seconds) to select it
- A subtle highlight box appears around the selected digit pair
- Arrow keys (up/down) increment/decrement the selected value
- Typing digits replaces the value: first digit typed clears the field and becomes the tens digit, second digit fills the ones position and auto-deselects. E.g., on minutes showing "25": type "0" → shows "0_", type "7" → shows "07", auto-deselects.
- Minutes clamp to 0–99, seconds clamp to 0–59
- Click elsewhere, Enter, or Escape to deselect

### Keyboard shortcuts (when app window is focused)
- `Space` — play/pause the focused timer
- `R` — reset the focused timer to its set value
- `1` / `2` — set keyboard focus to Timer 1 / Timer 2 (determines which timer Space/R apply to). Default focus: T1. A subtle focus ring or highlight on the active timer panel indicates which is focused.
- `Tab` — when a digit pair is selected, toggle between minute/second selection
- `Up/Down` — adjust selected digits
- `Enter/Esc` — confirm/cancel digit editing

### Input while running
- Digit editing is disabled while a timer is running. Clicking digits on a running timer does nothing.
- The timer must be stopped first to edit its time.

## Notifications & Sound

### Alerts
- **T1 completion (chained):** Short beep + macOS notification banner ("Timer 1 complete — Timer 2 started")
- **T2 / standalone completion:** Full alarm sound + notification banner ("Timer complete!")
- Alarm continues until user clicks the app or presses any key, with a maximum duration of 60 seconds

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
State for a single timer: remaining/elapsed time, target time, mode (countdown/timer), running state. Internally uses a `startDate` reference point; elapsed time is computed as `Date.now - startDate`. The view layer uses `TimelineView(.animation)` to drive display refresh — the model itself has no timer/runloop dependency.

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
      │    └── TimerControls (play/pause, reset)
      ├── ChainLinkButton
      ├── TimerPanelView (Timer 2)
      │    ├── ModeArrow
      │    ├── SevenSegmentDisplay
      │    └── TimerControls (play/pause, reset — hidden when chained)
      ├── SettingsButton
      └── SettingsView (sheet/window)
```
