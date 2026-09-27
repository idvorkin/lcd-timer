# On the Mac

Where the timer lives: a floating window, full screen, the menu bar.

Part of the [user stories](README.md); persona, format and the Status vocabulary are described there.

---

### User Story 008:

- **Summary:** A small timer window that floats above my work
- **Status:** implemented in 4de308b, 2359155 (translucent panel); builds and launches on the Mac; the panel over content verified in `just snapshots`; pinning is Igor's check pending

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

- **Notes:** ⌘P toggles the pin; unpinned, it is an ordinary window. The pin and the window's frame are
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
- **Status:** not implemented
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
