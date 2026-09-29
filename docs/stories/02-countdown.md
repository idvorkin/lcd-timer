# Running a countdown

Setting, starting, pausing and finishing a countdown from the keyboard.

Part of the [user stories](README.md); persona, format and the Status vocabulary are described there.

---

### User Story 004:

- **Summary:** Type a time like a microwave
- **Status:** implemented in 4de308b; verified on the host (entry, normalising); the keys in the app are Igor's check pending

#### Use Case:
- **As a** person who knows how long they want
- **I want to** type the digits and press Return
- **so that** setting a timer takes one second and no mouse

#### Acceptance Criteria:
- **Scenario:** Setting five minutes
- **Given:** the timer window is focused and idle
- **When:** I type `5`, `0`, `0` and press Return
- **Then:** the display fills from the right as I type (`00:05`, `00:50`, `05:00`) and Return starts a five-minute countdown

- **Scenario:** Starting again
- **Given:** a countdown has finished or was reset
- **When:** I press Return without typing
- **Then:** the last time I set starts again, also after the app was quit and reopened

- **Notes:** Backspace removes the last digit. Seconds typed past 59 are normalised when the countdown starts
  (`90` → `01:30`).
- **Issues:** none yet

---

### User Story 005:

- **Summary:** Start, pause, resume and reset from the keyboard
- **Status:** implemented in 4de308b; verified on the host (toggle, reset); the keys and the click are Igor's check pending

#### Use Case:
- **As a** person with their hands busy
- **I want to** control the timer with one key
- **so that** I never have to aim at a button

#### Acceptance Criteria:
- **Scenario:** Pausing mid-way
- **Given:** a countdown is running in the focused window
- **When:** I press Space, then Space again
- **Then:** the first press pauses it and shows *PAUSEd*, the second resumes it from the same time

- **Scenario:** Resetting
- **Given:** a countdown is running, paused or done
- **When:** I press Escape
- **Then:** the timer goes back to the time it was set to, idle and white

- **Notes:** A click anywhere on the digits does what Space does.
- **Issues:** none yet

---

### User Story 006:

- **Summary:** Time's up is impossible to miss
- **Status:** implemented in 4de308b; builds and launches on the Mac; the chime and the notification are Igor's check pending

#### Use Case:
- **As a** person who has stopped watching the timer
- **I want to** be told when it reaches zero, even if the window is behind others
- **so that** I don't overrun the set, the talk or the focus block

#### Acceptance Criteria:
- **Scenario:** Reaching zero with the window hidden
- **Given:** a countdown is running and the window is behind other windows
- **When:** it reaches zero
- **Then:** a chime plays once, the display reads *donE* in red, and a macOS notification says the timer is done; clicking it brings the window forward

- **Notes:** Counting up past zero to show how far over you are (for talks) is a candidate for a later story.
- **Issues:** none yet

---

### User Story 007:

- **Summary:** The time stays right through sleep and a busy Mac (technical)
- **Status:** implemented in 4de308b; verified on the host with an injected clock; a real lid close is Igor's check pending

#### Use Case:
- **As a** person whose Mac sleeps, or who hides the window for an hour
- **I want to** find the countdown exactly where the clock says it should be
- **so that** the timer is trusted without watching it

#### Acceptance Criteria:
- **Scenario:** The lid closes mid-countdown
- **Given:** a ten-minute countdown with six minutes left
- **When:** I close the lid for two minutes and open it again
- **Then:** the display shows four minutes left within a second of waking; had it run out while asleep, it reads *donE* and the notification is waiting

- **Notes:** The countdown stores its end time and derives the display from the clock; the tick only redraws.
  This state machine lives in the platform-free core and is tested on the host with an injected clock.
- **Issues:** none yet

---

### User Story 013:

- **Summary:** ? shows every key
- **Status:** implemented in 9f4934f, 7a247e8 (a click on the list over the corner buttons only dismisses it); the list verified in `just snapshots`; the key, the corner button and that click are Igor's check pending
- **Why:** "a ? to see the bindings, I don't see how to do it"

#### Use Case:
- **As a** person who forgot, or never learned, which key does what
- **I want to** press ? and see every key with what it does
- **so that** keyboard-first never means guessing

#### Acceptance Criteria:
- **Scenario:** Looking up the keys
- **Given:** the timer window is focused
- **When:** I press ?, or click the small ? in the window's top-right corner
- **Then:** the face is covered by the list of keys, amber keys beside what they do; the next key press or a click puts it away without doing anything else, and the countdown carries on underneath

- **Notes:** The list is `KeysHelp.bindings`; a new key adds its row there. `just snapshots` writes
  `keys-480x200.png`.
- **Issues:** none yet
