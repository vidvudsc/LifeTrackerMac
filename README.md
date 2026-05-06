# LifeTrackerMac

Native SwiftUI macOS version of LifeTracker.

It tracks local metadata only:

- foreground app names through `NSWorkspace`
- file create/modify/delete events under selected watch roots
- coding sessions inferred from file activity
- simple local JSON persistence in Application Support

It does not record screenshots, keystrokes, file contents, browser URLs, or window titles.

## Run

```bash
swift run -c release LifeTrackerMac
```

## Build

```bash
swift build -c release
```

The app defaults to watching:

```text
/Users/vidvudscalitis/Desktop/CODING
```
