# YouTube Cleaner for macOS

YouTube Cleaner is a native SwiftUI desktop application for inspecting and cleaning a YouTube library. Its Python/Playwright automation worker is included in this repository and application bundle; no separate worker checkout is required.

> Browser automation depends on YouTube's rendered website and can be affected by UI changes. The worker stops on ambiguous selectors or unverifiable changes instead of guessing.

## Current status

The development build provides:

- native account verification and Chrome sign-in;
- read-only Likes, Watch Later, and playlist scans;
- JSON and CSV exports;
- filtered cleanup previews and confirmed execution;
- item limits and continuous discovery;
- live progress, readable activity output, and safe interruption;
- local job history with detail and resume controls;
- selector and authentication diagnostics; and
- persistent browser, delay, and debug settings.

The Python worker, CPython 3.14 runtime, required Python packages, and Playwright Chromium are bundled into the built app. Runtime operations require no separate worker checkout, Python install, `pip install`, or browser install.

## Architecture

```text
┌───────────────────────────────┐
│ Native SwiftUI application    │
│ Views, settings, confirmation │
│ progress, jobs, activity log  │
└───────────────┬───────────────┘
                │ background Process + structured progress records
┌───────────────▼───────────────┐
│ Bundled Python worker          │
│ Planning, safety, checkpoints │
│ Playwright and page selectors │
                │ local CDP connection
┌───────────────▼───────────────┐
│ Dedicated Chrome profile      │
│ Normal visible YouTube site   │
└───────────────────────────────┘
```

The Swift app never displays a Terminal window. It launches the worker with redirected standard input and output, consumes structured progress events, and renders logs in the **Activity** panel.

The Python engine remains authoritative for account matching, cleanup planning, browser navigation, change verification, backups, and resumable checkpoints. This preserves the tested automation logic instead of reimplementing Playwright behavior in Swift.

## Requirements

- macOS 14 or later
- Git
- Xcode Command Line Tools with a Swift 6-capable toolchain
- `uv` and internet access when building (the build script downloads and packages CPython, worker dependencies, and Chromium)
- Google Chrome is optional; it supports the native-login workflow. Bundled Playwright Chromium is available without Chrome.

## Installation

The build script bundles a compatible Python runtime and worker dependencies:

Build the macOS application:

```sh
git clone git@github.com:suhermanme/swift-youtube-cleaner.git
cd swift-youtube-cleaner
xcrun swift test
./scripts/build-app.sh
```

The build script creates and ad-hoc signs:

```text
dist/YouTube Cleaner.app
```

Open that application from Finder. Day-to-day operation does not require Terminal.

## Build and test

After installation, rebuild and test from this repository with:

```sh
xcrun swift test
./scripts/build-app.sh
```

For a debug bundle:

```sh
./scripts/build-app.sh debug
```

The worker, Python runtime, packages, and Chromium are included in the application bundle. No runtime installation or worker path selection is needed.

## Native Chrome login

Native login is handled directly by the macOS app rather than a console prompt:

1. Select **Google Chrome** in the toolbar.
2. Click **Native Chrome login**.
3. Sign in to YouTube in the dedicated Chrome window.
4. Select the YouTube profile whose library should be managed.
5. Return to YouTube Cleaner and click **Finish Login**.
6. The app closes the exact Chrome application instance it launched and automatically continues with profile verification.

You do not normally need to press Command-Q, return to Terminal, or press Enter. If **Finish Login** cannot close Chrome within the timeout, the login sheet displays an inline warning. Quit that dedicated Chrome window manually and choose **Try Again**. Cancelling the login sheet closes the dedicated Chrome application instance without leaving a waiting worker.

The app uses this dedicated profile:

```text
~/.local/share/youtube-cleaner/browser-profile/
```

It does not import cookies from or point automation at the normal Chrome profile.

## Recommended cleanup workflow

1. Complete **Native Chrome login** if the dedicated profile is not authenticated.
2. Click **Verify account** and check the displayed channel name and handle.
3. Run a read-only scan or export for the intended library area.
4. Select **Preview / Dry Run** and inspect the planned targets.
5. Enable a limit of `1` and execute a canary cleanup.
6. After verifying the result in YouTube, execute the intended selection.
7. If an operation is interrupted, open **Jobs** and resume its checkpoint.

For unrestricted large libraries, **Keep discovering** repeatedly rescans the rendered feed until the worker reaches its convergence threshold. It is available only with **All items**, no limit, and no filters.

## Safety model

- Scanning, exporting, and previews do not modify YouTube.
- Execution requires a native confirmation dialog.
- The active YouTube profile is checked again before changes begin.
- Every confirmed change is checkpointed locally.
- Ambiguous page state, selector changes, and unverifiable results stop the operation.
- **Stop Safely** sends an interrupt so the worker can save the current checkpoint.
- Owned-playlist deletion and removal of saved external playlists use separate verified actions.
- The dedicated browser profile is isolated from the user's everyday Chrome profile.

## Local files

The Swift interface reads the same state used by the Python worker:

```text
~/.local/share/youtube-cleaner/browser-profile/          Dedicated Chrome profile
~/.local/share/youtube-cleaner/browser-profile-chromium/ Dedicated Chromium profile
~/.local/share/youtube-cleaner/backups/                  Cleanup backups
~/.local/share/youtube-cleaner/exports/                  JSON and CSV exports
~/.local/state/youtube-cleaner/jobs/                     Resumable checkpoints
~/.local/state/youtube-cleaner/logs/                     Worker logs
~/.local/state/youtube-cleaner/debug/                    Optional diagnostics
```

`XDG_DATA_HOME` and `XDG_STATE_HOME` override the corresponding base directories when set.

## Troubleshooting

The worker, Python runtime, packages, and browser are bundled. Rebuild the app with `./scripts/build-app.sh` if the bundle reports a missing runtime component.

### Native login still displays the old console-style instructions

Quit every running copy of YouTube Cleaner, then open the newly built application from `dist/YouTube Cleaner.app`. macOS may otherwise reactivate an older process that was already open.

### Finish Login cannot close Chrome

Make sure the window belongs to the dedicated YouTube Cleaner profile. Quit that Chrome instance manually, then click **Try Again**. The app tracks and closes only the separate Chrome application instance that it launched for this workflow.

### An operation exits with a nonzero code

Read the **Activity** panel for the worker's explanation. Enable **Debug diagnostics** in Settings and rerun the read-only operation if the failure appears related to a YouTube UI change.

### Jobs do not appear

Click **Refresh** in the Jobs view and verify the worker's state directory. A job is created only after cleanup execution begins; scans and dry runs do not create resumable cleanup jobs.

## Project layout

```text
Package.swift
Resources/
  AppIcon.icns           Multi-resolution application icon
  Info.plist
Sources/
  YouTubeCleanerCore/       Command validation and progress parsing
  YouTubeCleanerApp/        SwiftUI application and worker bridge
    Views/                  Library, Jobs, Diagnostics, Help, Activity, Settings
Tests/
  YouTubeCleanerCoreTests/  Command and stream-protocol tests
scripts/
  build-app.sh              Release/debug .app bundler
```

The generated `.app` is ad-hoc signed for local development. A portable release
still requires signing with an Apple Developer ID certificate and
notarizing/stapling the bundle. The app bundle includes its Python runtime,
worker dependencies, and Playwright Chromium.

## CI and releases

Pull requests and pushes to `main` run `xcrun swift test` on macOS. Pushing a
tag matching the app version (for example, `v0.1.0`) runs the tests, builds the
self-contained app, and publishes a ZIP plus SHA-256 checksum as a GitHub
release. Releases use this repository's MIT license.

Release assets are ad-hoc signed for local use. Developer ID signing and
notarization are not configured; macOS may require users to approve the app
before first launch.


## License

YouTube Cleaner for macOS is available under the [MIT License](LICENSE).
