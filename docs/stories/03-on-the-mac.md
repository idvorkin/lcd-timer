# On the Mac

Where the timer lives: a floating window, full screen, the menu bar.

Part of the [user stories](README.md); persona, format and the Status vocabulary are described there.

---

### User Story 008:

- **Summary:** A small timer window that floats above my work
- **Status:** implemented in 4de308b, 2359155 (translucent panel), 4b95f31 (pinned by default, pin button); builds and launches on the Mac; the panel over content verified in `just snapshots`; pinned over full-screen iTerm2 verified on the Mac from the window list (layer 3, on screen); the pin button is Igor's check pending

#### Use Case:
- **As a** person working in other apps while the timer runs
- **I want to** keep the timer visible on top of everything, without a title bar in the way
- **so that** it is a small clock on my screen rather than a window I manage

#### Acceptance Criteria:
- **Scenario:** Working with the timer pinned
- **Given:** the timer window is pinned on top
- **When:** I switch to another app and bring its window over the timer
- **Then:** the timer stays in front, is only the black LED panel, can be dragged from anywhere on it, and follows me to other Spaces

- **Scenario:** The timer sits over something
- **Given:** the timer window is over a document or a video
- **When:** I look at it
- **Then:** the black panel is slightly translucent, so what is underneath still shows faintly, while the digits stay as readable as on solid black; in full screen the panel is solid black

- **Scenario:** Opening it over a full-screen app
- **Given:** I work in a full-screen app, such as iTerm2 in its own Space, and have never unpinned the timer
- **When:** I launch the timer or ⌘Tab to it
- **Then:** it shows over the full-screen app, pinned; a small pin in the window's top-right corner unpins it (and pins it again), the same as ⌘P

- **Notes:** ⌘P toggles the pin; unpinned, it is an ordinary window, which macOS keeps off a full-screen app's
  Space (measured: the window lived on a desktop Space while ⌘Tab made the app active with nothing on screen),
  so a first launch is pinned. The pin and the window's frame are
  remembered. The panel is black at 75% opacity (`TimerFaceView.windowedOpacity`); `just snapshots` writes
  `running-over-content.png` to judge it.
- **Issues:** none yet

---

### User Story 009:

- **Summary:** Full screen turns the Mac into a wall clock
- **Status:** implemented in 4de308b; builds and launches on the Mac; ⌃⌘F and the three-metre read are Igor's check pending

#### Use Case:
- **As a** person using a Mac or an external display as the gym clock
- **I want to** put the timer full screen with nothing but the digits
- **so that** I can read it from across the room

#### Acceptance Criteria:
- **Scenario:** Going full screen during a set
- **Given:** a countdown is running in the window
- **When:** I press ⌃⌘F
- **Then:** the display fills the screen on black, the digits span its width, the pointer hides until moved, and the countdown carries on unaffected; from three metres the minutes and seconds are readable and the colour is obvious

- **Issues:** none yet

---

### User Story 010:

- **Summary:** The time left is in the menu bar
- **Status:** implemented in 4de308b; the pill verified in `just snapshots`; the live menu bar item is Igor's check pending

#### Use Case:
- **As a** person who has hidden or closed the timer window
- **I want to** see the time left in the menu bar and control the timer from there
- **so that** the timer never costs me screen space when I don't want it

#### Acceptance Criteria:
- **Scenario:** Closing the window mid-countdown
- **Given:** a countdown is running
- **When:** I close the timer window
- **Then:** the menu bar shows the time left, updating each second and in the state's colour, and its menu offers Pause/Resume, Reset and Show Timer

- **Notes:** Closing the window never stops a running countdown. Idle and with no window open, the menu bar
  item is a small LED `8` only.
- **Issues:** none yet

---

### User Story 011:

- **Summary:** The timer has its own icon, so I can find it in ⌘Tab and the Dock
- **Status:** implemented in 85ea3fe; the rendered iconset checked by eye; ⌘Tab is Igor's check pending
- **Why:** "you need an icon so it shows up in alt tab"

#### Use Case:
- **As a** person switching between apps with ⌘Tab
- **I want to** see the timer as an LED clock among the app icons
- **so that** I can jump back to it without hunting for a blank generic icon

#### Acceptance Criteria:
- **Scenario:** Switching back to the timer
- **Given:** the timer is running and I am in another app
- **When:** I hold ⌘Tab
- **Then:** the timer shows as a black rounded square with a red LED `5:00`, drawn in the same segments as the face

- **Notes:** The icon is drawn, not a checked-in bitmap: `LCDTimer --icon <dir>.iconset` renders the LED view at
  every size and `just app` runs `iconutil` into `Contents/Resources/AppIcon.icns`.
- **Issues:** none yet

---

### User Story 012:

- **Summary:** Lock me out of the Mac for the length of the countdown
- **Status:** implemented in 7cea64e, 12479be (corner button); verified on the host (lines, asking, timeout); the look in `just snapshots`; covering every screen, the keys and ⌘Tab blocked are Igor's check pending
- **Why:** "a button which I press locks me out for that time (though I can abort)… maybe a motivational thing like are you sure? With some eulogy lines"

#### Use Case:
- **As a** person starting a focus block who knows they will drift to other apps
- **I want to** grey out the whole Mac until the countdown ends, with leaving early one deliberate question away
- **so that** keeping the block is the easy path and quitting it is a choice I make on purpose

#### Acceptance Criteria:
- **Scenario:** Locking for a focus block
- **Given:** the timer window is focused and idle
- **When:** I type `2`, `5`, `0`, `0` and press L
- **Then:** a 25-minute countdown starts and every screen is covered by a dark grey veil with the red LED time under an amber *LOCd* and a line beneath that changes each minute; the Dock, menu bar and ⌘Tab are off; at zero the veil lifts by itself with the usual chime and *donE*

- **Scenario:** Wanting out
- **Given:** the screen is locked
- **When:** I press Escape
- **Then:** the time gives way to "Are you sure?" and a different line; Y resets the timer and lifts the veil, any other key (or 20 seconds of nothing) goes back to the lock

- **Scenario:** Finding the lock without knowing the key
- **Given:** the timer window shows the time
- **When:** I look for a way to lock
- **Then:** a small dim lock sits in the window's top-right corner; clicking it does what L does, and hovering names the key

- **Scenario:** Reaching for ⌘Q
- **Given:** the screen is locked
- **When:** I press ⌘Q, ⌘W or any other ⌘ key
- **Then:** the app does not quit and the lock stays; the key does what Escape does, so "Are you sure?" asks first

- **Notes:** The duration is the timer's own: L with nothing typed locks for the last time set, and L on a running
  or paused countdown locks the rest of it. Space does nothing while locked, since a pause would hold the lock
  forever. The menu bar menu has *Lock Me Out*. ⌥⌘Esc still force-quits: a speed bump, not a jail. ⌘ keys reach
  the app's main menu before the lock screen, so a local key monitor catches them while locked; unlocked, ⌘Q
  quits as usual. The lines
  are eulogy virtues over résumé virtues (`Lockout.lines`); `just snapshots` writes `locked.png` and
  `lock-asking.png`.
- **Issues:** none yet
