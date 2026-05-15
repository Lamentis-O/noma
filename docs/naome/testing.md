# Testing And Verification

Status: Partial

## Verification Map

| Change type | Required proof | Command | Notes |
|---|---|---|---|
| Swift app source | Xcode simulator build plus NAOME changed-file gates | `xcodebuild -project Noma.xcodeproj -scheme Noma -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/noma-derived-data build` | Verified on 2026-05-15 outside the sandbox. |
| Xcode project/assets | Xcode project listing, Xcode simulator build, NAOME gates | See Known Checks | Project listing and build are verified. |
| npm/package tooling | npm install plus NAOME gates | `npm install` | Verified during NAOME package installation. |
| NAOME harness/docs | Harness health plus NAOME gates | `node .naome/bin/check-harness-health.js` | Verified on 2026-05-15. |
| XCTest/UI test edits | Not fully confirmed | Unknown | Repo has test targets, but a default simulator test destination is not yet confirmed. |

## Early Feedback

After writing or heavily editing a file, run
`node .naome/bin/naome.js quality check --path <path>` for immediate
touched-file feedback. This catches local size, symbol, duplicate, structure,
and stale-policy issues before the task grows. It does not replace the final
`repository-quality-check`; always run the changed-file gate before completion.

## Known Checks

| Check id | Command | Cwd | Cost | Last verified |
|---|---|---|---|---|
| npm-install | `npm install` | `.` | fast | 2026-05-15 |
| xcode-list | `xcodebuild -list -project Noma.xcodeproj` | `.` | fast | 2026-05-15 |
| xcode-build-ios-simulator | `xcodebuild -project Noma.xcodeproj -scheme Noma -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/noma-derived-data build` | `.` | medium | 2026-05-15 |
| diff-check | `git diff --check` | `.` | fast | null |
| naome-harness-health | `node .naome/bin/check-harness-health.js` | `.` | fast | 2026-05-15 |
| naome-task-state | `node .naome/bin/check-task-state.js` | `.` | fast | null |
| repository-quality-check | `node .naome/bin/naome.js quality check --changed` | `.` | fast | null |
| repository-semantic-check | `node .naome/bin/naome.js semantic check --changed` | `.` | fast | null |
| ui-style-check | `node .naome/bin/naome.js ui check --changed --json` | `.` | fast | null |
| architecture-fitness-check | `node .naome/bin/naome.js arch validate --changed-only` | `.` | fast | null |

## Verification Phases

Run checks in `.naome/verification.json` phase order:
`shape-health`, `quality`, `focused-tests`, `broad-tests`, `package-release`,
then `diff-check`. Do not recommend later expensive phases while an earlier
phase is failing or missing.

## Change Type Rules

| Change type | Paths | Required checks |
|---|---|---|
| iOS app source | `Noma/**/*.swift`, `Noma/Assets.xcassets/**` | `xcode-build-ios-simulator`, `repository-quality-check`, `repository-semantic-check`, `ui-style-check`, `architecture-fitness-check`, `diff-check` |
| iOS tests | `NomaTests/**/*.swift`, `NomaUITests/**/*.swift` | `xcode-build-ios-simulator`, `repository-quality-check`, `repository-semantic-check`, `architecture-fitness-check`, `diff-check`; simulator test command still needs confirmation |
| Xcode project | `Noma.xcodeproj/**` | `xcode-list`, `xcode-build-ios-simulator`, `repository-quality-check`, `architecture-fitness-check`, `diff-check` |
| npm tooling | `package.json`, `package-lock.json`, `.gitignore` | `npm-install`, `repository-quality-check`, `repository-semantic-check`, `diff-check` |
| NAOME harness/docs | `.naome/**`, `.naomeignore`, `AGENTS.md`, `docs/naome/**` | `naome-harness-health`, `repository-quality-check`, `repository-semantic-check`, `architecture-fitness-check`, `diff-check` |

## Release Gates

| Check id | Required when |
|---|---|
| xcode-build-ios-simulator | Before shipping or merging app/source/project changes. |
| naome-harness-health | Before normal NAOME-routed work and before merging harness changes. |

## Evidence

- `.naome/verification.json`
- `.naome/repository-model.json`
- `.naome/repository-quality.json`
- `.naome/repository-structure.json`
- `Noma.xcodeproj/project.pbxproj`
- `Noma/NomaApp.swift`
- `Noma/ContentView.swift`
- `NomaTests/NomaTests.swift`
- `NomaUITests/NomaUITests.swift`
- `package.json`
- `package-lock.json`
- Command: `npm install`
- Command: `xcodebuild -list -project Noma.xcodeproj`
- Command: `xcodebuild -project Noma.xcodeproj -scheme Noma -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/noma-derived-data build`

## Open Questions

- Confirm the default simulator destination for running `NomaTests` and
  `NomaUITests`.
- Confirm whether CI should run npm, NAOME, and Xcode checks.
