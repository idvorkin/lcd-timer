# Agent instructions: LCD Timer

macOS app (SwiftUI) that shows a countdown as a seven-segment LED display, the Gym Timer's look from
context-grabber on the Mac. `TimerCore/` is the platform-free package (glyphs, geometry, the countdown state
machine); `LCDTimer/` is the app. Neither exists yet: the stories come first.

## Read these before working

| File | What it settles |
|---|---|
| [docs/stories/README.md](docs/stories/README.md) | the spec: user stories per journey, each with its status and commits |
| context-grabber `lib/gym/sevenSegment.ts`, `components/LedDisplay.tsx` | the glyph table and the geometry being ported |

## Rules

- **Every feature or behaviour change updates the user stories** (`docs/stories/`) in the same commit or the
  next: a new capability gets a story in its journey (Cohn + Gherkin, `user-story` skill) with a `Status:` line
  naming its commit and where it was verified; a changed behaviour edits the story's acceptance criteria and adds
  its commit to the `Status:` line. Status lives only on the stories. No story, not done.
- **Test ladder**: host `swift test` in `TimerCore/` → the app on the Mac. Verify on the cheapest rung that can
  see the change and say which rung you used. Anything with a clock takes an injected clock so it is tested on the
  host, never by waiting.
- **Drawn, not typed.** The digits are SwiftUI shapes from the glyph table; no LED font is bundled.
- **Instrument before theorizing.** For a symptom that only shows in the running app, add a log line, run, read
  it, then fix from evidence. Never ship a second guessed fix.
- **One commit per issue**, referencing it. Never bundle fixes. Never `git add -A` (`.build/`, `Build/` must
  stay untracked).
- **Edit files with the Read, Edit and Write tools.** Not with Python or sed scripts wrapped in a shell command:
  Igor reads the diffs, and a tool edit shows exactly what changed. Shell is for building, testing and git.
- **Keyboard first.** Every action has a key; the mouse is never required. Propose with a numeric plan or a
  trade-off table, then one "do it".
