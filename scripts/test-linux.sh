#!/usr/bin/env bash
# The Linux rung: what a Linux box can say about this package without a Mac.
#   1. TimerCore's tests, built and run on Linux Swift. Only the test product is built: the app (AppKit, SwiftUI) and
#      BugKit (Darwin) do not build on Linux, and a plain `swift test` builds every target.
#   2. The app and TimerCore cross-built for arm64-apple-macosx with a Darwin Swift SDK (xtool's): Mach-O compiled,
#      linked, never run. Release, because debug ends in a codesign step Linux lacks. The tests are not cross-built:
#      they are Swift Testing, and the Darwin SDK has no `_Testing_Foundation`. Skipped, and said so, without a
#      `darwin` SDK.
# Neither runs the app, signs it or renders anything: `just test`, `just snapshots` and `just run` on the Mac do.
#
# Environment (all optional):
#   LINUX_SWIFT_BIN  the Swift toolchain's bin directory, when `swift` on PATH is not the one to use
#   LINUX_LIB_DIR    extra libraries for the toolchain and the link (LD_LIBRARY_PATH and -L), e.g. an ICU it needs
#   LCD_LINUX_BUILD  a build directory to keep between runs (default: a temporary one, removed afterwards)
#   JOBS             build jobs (default 3)
set -uo pipefail
cd "$(dirname "$0")/.."
[ "$(uname -s)" = Linux ] || { echo "test-linux is the Linux rung; on a Mac run just test" >&2; exit 2; }
[ -n "${LINUX_SWIFT_BIN:-}" ] && export PATH="$LINUX_SWIFT_BIN:$PATH"
command -v swift >/dev/null || { echo "no swift on PATH (set LINUX_SWIFT_BIN)" >&2; exit 2; }
flags=()
if [ -n "${LINUX_LIB_DIR:-}" ]; then
  export LD_LIBRARY_PATH="$LINUX_LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  flags+=(-Xlinker "-L$LINUX_LIB_DIR")
fi
build=${LCD_LINUX_BUILD:-}
if [ -z "$build" ]; then
  build=$(mktemp -d "${TMPDIR:-/tmp}/lcd-test-linux.XXXXXX")
  trap 'rm -rf "$build"' EXIT
fi
mkdir -p "$build"
jobs=${JOBS:-3}
low() { nice -n 19 ionice -c 3 "$@"; }
fail=0

echo "== $(swift --version 2>&1 | head -1)"
echo "== Linux: TimerCore tests ($(uname -m))"
log=$build/linux-test.log
{
  low swift build --product LCDTimerPackageTests -j "$jobs" --scratch-path "$build/linux" "${flags[@]}" &&
    low swift test --skip-build -j "$jobs" --scratch-path "$build/linux" "${flags[@]}"
} >"$log" 2>&1
status=$?
grep -E "error:|✘" "$log" | head -20
summary=$(grep -E "Test run with [0-9]+ tests" "$log" | tail -1)
if [ $status -ne 0 ] || [ -z "$summary" ]; then
  echo "FAIL Linux tests (exit $status; log: $log)"
  fail=1
else
  echo "ok   ${summary#* }"
fi

if swift sdk list 2>/dev/null | grep -qx darwin; then
  triple=arm64-apple-macosx
  sdk=$(swift sdk configure --show-configuration darwin "$triple" 2>/dev/null | sed -n 's/^sdkRootPath: //p')
  log=$build/$triple.log
  if low swift build -c release --build-system native --swift-sdk darwin --triple "$triple" -j "$jobs" \
    --scratch-path "$build/$triple" >"$log" 2>&1; then
    echo "ok   cross-build $triple: LCDTimer + TimerCore compiled and linked, not run (SDK $(basename "${sdk:-?}"))"
  else
    grep -E "error:" "$log" | head -20
    echo "FAIL cross-build $triple (log: $log)"
    fail=1
  fi
else
  echo "SKIP cross-build: no darwin Swift SDK (xtool sdk install)"
fi
# A failure keeps its logs, even in the temporary directory.
if [ $fail -ne 0 ] && [ -z "${LCD_LINUX_BUILD:-}" ]; then
  trap - EXIT
  echo "logs kept in $build"
fi
exit $fail
