app := "build/LCD Timer.app"
installed := "/Applications/" + file_name(app)

default:
    @just --list

# Host tests for TimerCore (~1 s). The first rung of the test ladder.
test:
    swift test

# Build a release binary and wrap it into a signed app bundle (notifications need the bundle).
app:
    swift build -c release
    rm -rf "{{app}}"
    mkdir -p "{{app}}/Contents/MacOS" "{{app}}/Contents/Resources"
    cp "$(swift build -c release --show-bin-path)/LCDTimer" "{{app}}/Contents/MacOS/"
    cp Support/Info.plist "{{app}}/Contents/"
    rm -rf build/AppIcon.iconset
    "{{app}}/Contents/MacOS/LCDTimer" --icon build/AppIcon.iconset
    iconutil -c icns build/AppIcon.iconset -o "{{app}}/Contents/Resources/AppIcon.icns"
    codesign --force --sign - "{{app}}"

# Build the app and open it: the second rung.
run: app
    -pkill -x LCDTimer
    open "{{app}}"

# Copy the app into /Applications: a snapshot that later builds leave alone.
install: app
    rm -rf "{{installed}}"
    cp -R "{{app}}" "{{installed}}"

# Symlink /Applications to this checkout's build, so each `just app` is what Spotlight and the Dock open.
# The link dangles while the disk holding this checkout is unmounted.
live-install: app
    rm -rf "{{installed}}"
    ln -s "{{justfile_directory()}}/{{app}}" "{{installed}}"

# Render every face and the menu bar pill to build/snapshots/*.png (no screen-recording permission needed).
snapshots: app
    rm -rf build/snapshots
    "{{app}}/Contents/MacOS/LCDTimer" --snapshots build/snapshots
    ls build/snapshots

# Stream the app's log (start, toggle, reset, wake, done).
logs:
    log stream --predicate 'subsystem == "com.idvorkin.lcdtimer"' --level info
