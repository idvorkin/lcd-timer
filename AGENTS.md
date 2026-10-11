# Agent instructions: LCD Timer

macOS app (SwiftUI) that shows a countdown as a seven-segment LED display, the Gym Timer's look from
context-grabber on the Mac. `Sources/TimerCore/` is the platform-free module (glyphs, geometry, the countdown
state machine, the typed entry, the face); `Sources/LCDTimer/` is the app. A plain SwiftPM package: no Xcode
project.

## Build

| Command | What it does |
|---|---|
| `just test` | host tests for TimerCore, about a second |
| `just fmt` | reformats every Swift file with swift-format (`.swift-format`) |
| `just lint` | fails on unformatted code, then on SwiftLint findings (`.swiftlint.yml`, `brew install swiftlint`) |
| `just run` | release build, wrapped into `build/LCD Timer.app`, ad-hoc signed, opened |
| `just install` | builds and copies the app into `/Applications` (a snapshot) |
| `just live-install` | builds and symlinks `/Applications/LCD Timer.app` to the build, so later builds are what opens |
| `just snapshots` | renders every face and the menu bar pill to `build/snapshots/*.png` |
| `just logs` | streams the app's log (start, toggle, reset, wake, done) |

- **Builds with the Command Line Tools, not Xcode.** The SDK's SwiftUI `@State` is a macro whose plugin ships
  only with Xcode, so the app does not use `@State`: the model is an `@Observable` class held by the `App`.
  Other SwiftUI macros would hit the same wall; check `swift build` after adding one.
- **Screenshots need Screen Recording permission**, which the terminal may not have. `just snapshots` renders
  the real views through `ImageRenderer` instead; look at those before claiming a visual change works.
- A "plugin for module … not found" error that appears after an interrupted build clears with `rm -rf .build`.

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
- **Test ladder**: host `just test` → `just snapshots` (the look) → `just run` (the app on the Mac, Igor's eye
  for windows, keys, sound and notifications). Verify on the cheapest rung that can see the change and say which
  rung you used. Anything with a clock takes an injected clock so it is tested on the host, never by waiting.
- **Drawn, not typed.** The digits are SwiftUI shapes from the glyph table; no LED font is bundled.
- **Instrument before theorizing.** For a symptom that only shows in the running app, add a log line, run, read
  it, then fix from evidence. Never ship a second guessed fix.
- **One commit per issue**, referencing it. Never bundle fixes. Never `git add -A` (`.build/`, `Build/` must
  stay untracked).
- **Edit files with the Read, Edit and Write tools.** Not with Python or sed scripts wrapped in a shell command:
  Igor reads the diffs, and a tool edit shows exactly what changed. Shell is for building, testing and git.
- **Keyboard first.** Every action has a key; the mouse is never required. Propose with a numeric plan or a
  trade-off table, then one "do it".
- **Shared practices for all apps live in idvorkin/bug-kit (README: Shared practices for every app).** A bug in
  BugKit code (dialog, dictation, store, crash capture, CloudKit, listener, What's new), or a practice that
  applies to every app, is filed on idvorkin/bug-kit and linked from here, never fixed in this repo.

## Pipeline (no-mistakes)

- **One pipeline run per train.** Finish the whole stack before the first push. Don't push while a run is in
  flight, unless review or test asked for that fix. Never restart the no-mistakes daemon or reboot while runs are
  active. Live checks (`just snapshots`, `just run`) happen once, in the driving session's build turn, and go in
  the PR body; the test step stays on the host (`test.instructions` in `.no-mistakes.yaml`).
- **Review settles in one fix round.** In round 1, fix every error and warning together. In later rounds, fix
  errors only and decide info findings in one pass. Cap review at 2 rounds; file the rest as issues.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:1105d646 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/core-concepts/sync-concepts.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->

<!-- BEGIN BEADS CODEX SETUP: generated by bd setup codex -->
## Beads Issue Tracker

Use Beads (`bd`) for durable task tracking in repositories that include it. Use the `beads` skill at `.agents/skills/beads/SKILL.md` (project install) or `~/.agents/skills/beads/SKILL.md` (global install) for Beads workflow guidance, then use the `bd` CLI for issue operations.

### Quick Reference

```bash
bd ready                # Find available work
bd show <id>            # View issue details
bd update <id> --claim  # Claim work
bd close <id>           # Complete work
bd prime                # Refresh Beads context
```

### Rules

- Use `bd` for all task tracking; do not create markdown TODO lists.
- Run `bd prime` when Beads context is missing or stale. Codex 0.129.0+ can load Beads context automatically through native hooks; use `/hooks` to inspect or toggle them.
- Keep persistent project memory in Beads via `bd remember`; do not create ad hoc memory files.

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/core-concepts/sync-concepts.md for details and anti-patterns.
<!-- END BEADS CODEX SETUP -->
