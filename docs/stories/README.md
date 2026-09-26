# LCD Timer — User Stories

These files are the spec. There is no separate narrative page: a feature exists when its story says so, and a
behaviour changes when its story changes. The persona throughout is **Igor at his Mac**: timing a set in the
home gym, a talk, or a focus block, with the clock readable from across the room.

| Journey | What it covers |
|---|---|
| [The LED look](01-display.md) | Digits that look like a gym's wall clock, at any size. |
| [Running a countdown](02-countdown.md) | Setting, starting, pausing and finishing a countdown from the keyboard. |
| [On the Mac](03-on-the-mac.md) | Where the timer lives: a floating window, full screen, the menu bar. |

## Format

Mike Cohn use case plus Gherkin acceptance criteria (deanpeters/Product-Manager-Skills `user-story`). Each
story has, in this order:

- **Summary**: one line, what Igor gets.
- **Status**: one line, see below.
- **Why** (optional): one line on what prompted it, Igor's words when they exist.
- **Use Case**: As a / I want to / so that.
- **Acceptance Criteria**: one or more scenarios, each with one When and one Then. A story starts with one
  scenario; a later change to its behaviour adds a scenario rather than rewriting the first, so the criteria
  read as the feature grew.
- **Notes** (optional): the mechanism, the trade-off that was decided. Short.
- **Issues**: the GitHub issues that asked for it or reported against it.

Stories are numbered in the order they were written and sit in their journey file in that order. A number is
never reused.

## Status

The Status line is the only record of where a story stands. It names the commits and the rung that verified
them, nothing else. The vocabulary:

- `implemented in <commits>; verified on the host` (or `on the Mac`).
- `…; Igor's check pending` when the build runs but the behaviour needs Igor's eye.
- `not implemented` when only the story exists, `not implemented (#N)` once it has an issue.

A commit that changes a behaviour adds itself to the story's Status and edits or adds the scenario it
changed, in the same commit or the next (AGENTS.md).
