# On the Mac

Where the timer lives: a floating window, full screen, the menu bar.

Part of the [user stories](README.md); persona, format and the Status vocabulary are described there.

---

### User Story 008:

- **Summary:** A small timer window that floats above my work
- **Status:** implemented in 4de308b; builds and launches on the Mac; pinning is Igor's check pending

#### Use Case:
- **As a** person working in other apps while the timer runs
- **I want to** keep the timer visible on top of everything, without a title bar in the way
- **so that** it is a small clock on my screen rather than a window I manage

#### Acceptance Criteria:
- **Scenario:** Working with the timer pinned
- **Given:** the timer window is pinned on top
- **When:** I switch to another app and bring its window over the timer
- **Then:** the timer stays in front, is only the black LED panel, can be dragged from anywhere on it, and follows me to other Spaces

- **Notes:** ⌘P toggles the pin; unpinned, it is an ordinary window. The pin and the window's frame are
  remembered.
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
