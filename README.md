# LCD Timer

A countdown for the Mac that looks like a gym's wall clock: glowing seven-segment digits with the unlit segments
faintly there, drawn rather than typed, as big as the window.

![Paused: amber PAUSEd over the frozen red time](docs/screenshots/paused.png)

- **Keyboard first.** Type `5` `0` `0` and Return for five minutes. Space pauses and resumes, Escape resets,
  Return with nothing typed runs the last time again.
- **Colour says the state.** White idle, red running, amber *PAUSEd*, red *donE* with a chime and a notification.
- **Stays out of the way.** ⌘P pins it on top of every window and Space, over a slightly translucent panel;
  ⌃⌘F makes the Mac a wall clock; close the window and the time left stays in the menu bar.
- **Lock me out.** L starts the countdown with every screen greyed out until zero. Escape asks "Are you
  sure?" with a line about what the minutes are for; Y gives up.
- **Always right.** The countdown keeps its end time, so sleep and a hidden window never make it drift.

![The translucent panel over other content](docs/screenshots/over-content.png)

## Build

Needs only the Command Line Tools and [`just`](https://github.com/casey/just).

```sh
just test         # host tests for TimerCore
just run          # builds "build/LCD Timer.app" and opens it
just install      # copies the app into /Applications
just live-install # links /Applications to the build, so each `just app` is what opens
```

The spec is the [user stories](docs/stories/README.md); agent rules are in [AGENTS.md](AGENTS.md). The LED look
is ported from the Gym Timer in [context-grabber](https://github.com/idvorkin/context-grabber).
