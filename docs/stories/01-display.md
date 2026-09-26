# The LED look

Digits that look like a gym's wall clock, at any size.

Part of the [user stories](README.md); persona, format and the Status vocabulary are described there.

---

### User Story 001:

- **Summary:** The time is a seven-segment LED display, not type
- **Status:** implemented in 4de308b; verified on the host (glyphs, ghosts, colon) and in `just snapshots`
- **Why:** "What I like is that old LCD countdown", the Gym Timer's LED face in context-grabber.

#### Use Case:
- **As a** person glancing at the timer from across the room
- **I want to** see the time as glowing seven-segment digits with the unlit segments faintly there
- **so that** it reads as one panel, like a gym clock, rather than as text on a screen

#### Acceptance Criteria:
- **Scenario:** Looking at a set timer
- **Given:** the timer is set to 12:34 and not running
- **When:** I look at the window
- **Then:** each digit is seven separate bars on black, the lit bars bright with a soft glow, the unlit bars dark ghosts so an `8` sits faintly behind every digit, and the colon is two LED dots

- **Notes:** Drawn, not a font: nothing to bundle and it scales to any size. Port the glyph table and the
  geometry (digit 0.55 × height wide, bar 0.11 × height, gap 0.13, bars inset from the corners, ghost
  `#242424`) from context-grabber's `lib/gym/sevenSegment.ts` and `components/LedDisplay.tsx`.
- **Issues:** none yet

---

### User Story 002:

- **Summary:** The digits fill whatever window they are in
- **Status:** implemented in 4de308b; verified on the host (`faceHeights`) and in `just snapshots` at two sizes; live resizing is Igor's check pending

#### Use Case:
- **As a** person who sizes the timer to fit the moment, a corner of the screen or the whole of it
- **I want to** have the digits grow and shrink with the window
- **so that** the time is always as big as the space allows

#### Acceptance Criteria:
- **Scenario:** Resizing the window
- **Given:** the timer shows 05:00 in a small window
- **When:** I drag the window's corner to make it wider or taller
- **Then:** the digits resize as I drag to the tallest height that fits the width, stay centred, and never clip or wrap

- **Notes:** `LedGeometry.faceHeights`: context-grabber's `ledHeightToFit` (the string's width at height 1,
  scaled to the window's width, capped by its height) extended to the word above and the glow around each string.
- **Issues:** none yet

---

### User Story 003:

- **Summary:** The colour and an LED word say what the timer is doing
- **Status:** implemented in 4de308b; verified on the host (the face per phase) and in `just snapshots`

#### Use Case:
- **As a** person who looks up mid-task
- **I want to** tell from the colour alone whether the timer is idle, running, paused or finished
- **so that** I never have to read anything but the digits

#### Acceptance Criteria:
- **Scenario:** Going through a countdown
- **Given:** a countdown is set and idle
- **When:** I start it, pause it, resume it and let it run out
- **Then:** the digits are white while idle, red while running, frozen in red under an amber *PAUSEd* in LED letters while paused, and read *donE* in steady red at zero; the LED words are spelled as a seven-segment display spells them

- **Notes:** The palette is the Gym Timer's: red `#ff3b30`, green `#34c759`, amber `#ffcc00`, white `#e6e6e6`.
  Green is kept for rest once rounds exist.
- **Issues:** none yet
