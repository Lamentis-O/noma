# Repository Profile

Status: Initialized

## Purpose

- Noma is intended to become an autonomous todo tracker with AI features and
  subscription-based SaaS monetization for iPhone users.
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
- Default simulator: the latest available `iPhone 17 Pro`; in this local
  checkout the selected iOS 26.2 simulator id is
  `E394FB54-CFA1-4765-B2FE-B7A90FE4A0AA`.
- Build command: `xcodebuild -project Noma.xcodeproj -scheme Noma -destination 'platform=iOS Simulator,id=E394FB54-CFA1-4765-B2FE-B7A90FE4A0AA' -derivedDataPath /private/tmp/noma-derived-data build`.
- Test command: not fully verified yet; use the latest available `iPhone 17 Pro`
  simulator for future XCTest/UI test runs.
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
- User confirmation on 2026-05-15: product purpose, iPhone 17 Pro simulator
  default, PR build requirement, and high-risk AI/subscription/payment areas.
- XcodeBuildMCP simulator listing on 2026-05-15: `iPhone 17 Pro` available;
  current selected iOS 26.2 simulator id is
  `E394FB54-CFA1-4765-B2FE-B7A90FE4A0AA`.

## Open Questions

- Should CI be added, and which checks should run in CI?
- Which exact subscription/payment backend and entitlement model should Noma
  use?
