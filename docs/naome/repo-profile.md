# Repository Profile

Status: Needs user context

## Purpose

- This repository contains a fresh iOS SwiftUI app named `Noma`.
- The current app behavior is the Xcode starter screen with `ContentView`
  rendering a globe symbol and `Hello, world!`.
- Product intent beyond the app name is not yet confirmed.

## Stack

- SwiftUI iOS application target `Noma`.
- XCTest unit-test target `NomaTests`.
- XCTest UI-test target `NomaUITests`.
- npm is present for repository tooling; `@lamentis/naome` is installed as the
  NAOME harness package.

## Project Layout

- `Noma.xcodeproj/`: Xcode project with scheme `Noma`.
- `Noma/`: SwiftUI app source and asset catalogs.
- `NomaTests/`: unit tests.
- `NomaUITests/`: UI tests and launch screenshot test.
- `.naome/` and `docs/naome/`: NAOME machine state and agent-facing docs.
- `package.json` and `package-lock.json`: npm manifest and lockfile for NAOME.

## Package And Tooling

- Package manager: npm.
- Install command: `npm install`.
- Xcode project listing: `xcodebuild -list -project Noma.xcodeproj`.
- Build command: `xcodebuild -project Noma.xcodeproj -scheme Noma -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/noma-derived-data build`.
- Test command: not yet confirmed; likely requires a concrete booted simulator
  destination for the `Noma` scheme.
- Lint command: none found.
- Typecheck command: covered by the Xcode build command.

## CI And Deployment

- CI: none found in the repository.
- Deployment: unknown.

## Existing Instructions

- Root agent instructions are in `AGENTS.md`.
- `.naomeignore` defines hard read boundaries for NAOME agents.

## Nested Agent Instructions

- No nested `AGENTS.md` files were found during intake.

## Evidence

- `Noma/NomaApp.swift`
- `Noma/ContentView.swift`
- `NomaTests/NomaTests.swift`
- `NomaUITests/NomaUITests.swift`
- `NomaUITests/NomaUITestsLaunchTests.swift`
- `Noma.xcodeproj/project.pbxproj`
- `package.json`
- `package-lock.json`
- `AGENTS.md`
- `.naomeignore`
- `.naome/repository-model.json`
- Command: `xcodebuild -list -project Noma.xcodeproj`
- Command: `xcodebuild -project Noma.xcodeproj -scheme Noma -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/noma-derived-data build`

## Open Questions

- What product experience should Noma become beyond the starter SwiftUI app?
- Which simulator/device should be the default for UI tests?
- Should CI be added, and which checks should run in CI?
