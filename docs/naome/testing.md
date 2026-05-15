# Testing And Verification

Status: Initialized

## Verification Map

| Change type | Required proof | Command | Notes |
|---|---|---|---|
| Swift app source | Xcode simulator build plus NAOME changed-file gates | `xcodebuild -project Noma.xcodeproj -scheme Noma -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /private/tmp/noma-derived-data build` | PR build gate; default simulator is latest available iPhone 17 Pro. |
| Xcode project/assets | Xcode project listing, Xcode simulator build, NAOME gates | See Known Checks | Project listing and build are verified. |
| npm/package tooling | clean npm install plus NAOME gates | `npm ci` | Verified from the committed lockfile. |
| GitHub Actions CI | Ubuntu NAOME checks plus macOS iOS build and test jobs | `.github/workflows/ci.yml` | PR CI runs on GitHub-hosted `ubuntu-latest` and `macos-26` runners. |
| NAOME harness/docs | Harness health plus NAOME gates | `node .naome/bin/check-harness-health.js` | Verified on 2026-05-15. |
| XCTest/UI test edits | iPhone 17 Pro simulator test run plus NAOME gates | `xcodebuild test -project Noma.xcodeproj -scheme Noma -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /private/tmp/noma-derived-data` | Test command is the intended path for future test edits; build gate is the current PR minimum. |
| AI, API usage, subscriptions, payments, and premium entitlements | Build plus targeted unit/integration tests and human review | To be defined with each feature | These areas are high risk and require strict verification before merge. |

## Early Feedback

After writing or heavily editing a file, run
`node .naome/bin/naome.js quality check --path <path>` for immediate
touched-file feedback. This catches local size, symbol, duplicate, structure,
and stale-policy issues before the task grows. It does not replace the final
`repository-quality-check`; always run the changed-file gate before completion.

## Known Checks

| Check id | Command | Cwd | Cost | Last verified |
|---|---|---|---|---|
| npm-install | `npm ci` | `.` | fast | 2026-05-15 |
| xcode-list | `xcodebuild -list -project Noma.xcodeproj` | `.` | fast | 2026-05-15 |
| xcode-build-ios-simulator | `xcodebuild -project Noma.xcodeproj -scheme Noma -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /private/tmp/noma-derived-data build` | `.` | medium | 2026-05-15 |
| xcode-test-iphone-17-pro | `xcodebuild test -project Noma.xcodeproj -scheme Noma -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /private/tmp/noma-derived-data` | `.` | medium | 2026-05-15 |
| diff-check | `git diff --check` | `.` | fast | null |
| naome-harness-health | `node .naome/bin/check-harness-health.js` | `.` | fast | 2026-05-15 |
| naome-task-state | `node .naome/bin/check-task-state.js` | `.` | fast | null |
| repository-quality-check | `node .naome/bin/naome.js quality check --changed` | `.` | fast | null |
| repository-semantic-check | `node .naome/bin/naome.js semantic check --changed` | `.` | fast | null |
| ui-style-check | `node .naome/bin/naome.js ui check --changed --json` | `.` | fast | null |
| architecture-fitness-check | `node .naome/bin/naome.js arch validate --changed-only` | `.` | fast | null |

## Continuous Integration

Pull requests and pushes to `main` run `.github/workflows/ci.yml`.

- `NAOME checks` installs npm dependencies from the public npm registry on
  `ubuntu-latest`, syncs the local NAOME harness, validates harness health,
  runs changed-file quality and semantic checks for the committed diff, runs
  architecture fitness, and checks diff whitespace.
- `iOS build and tests` runs on `macos-26`, lists the Xcode project, and runs
  `xcodebuild test` against the `iPhone 17 Pro` simulator. The test command
  builds the app before running XCTest/UI tests, so CI avoids a separate
  duplicate build step.
- The workflow uses read-only repository permissions and does not require
  secrets, signing assets, OpenAI keys, or payment credentials.

## Verification Phases

Run checks in `.naome/verification.json` phase order:
`shape-health`, `quality`, `focused-tests`, `broad-tests`, `package-release`,
then `diff-check`. Do not recommend later expensive phases while an earlier
phase is failing or missing.

## Change Type Rules

| Change type | Paths | Required checks |
|---|---|---|
| iOS app source | `Noma/**/*.swift`, `Noma/Assets.xcassets/**`, `Noma/AppIcon.icon/**` | `xcode-build-ios-simulator`, `repository-quality-check`, `repository-semantic-check`, `ui-style-check`, `architecture-fitness-check`, `diff-check` |
| iOS tests | `NomaTests/**/*.swift`, `NomaUITests/**/*.swift` | `xcode-build-ios-simulator`, `xcode-test-iphone-17-pro`, `repository-quality-check`, `repository-semantic-check`, `architecture-fitness-check`, `diff-check` |
| Xcode project | `Noma.xcodeproj/**` | `xcode-list`, `xcode-build-ios-simulator`, `repository-quality-check`, `architecture-fitness-check`, `diff-check` |
| npm tooling | `package.json`, `package-lock.json`, `.gitignore` | `npm-install`, `repository-quality-check`, `repository-semantic-check`, `diff-check` |
| GitHub Actions CI | `.github/workflows/**` | `naome-harness-health`, `repository-quality-check`, `repository-semantic-check`, `architecture-fitness-check`, `diff-check`; workflow also runs iOS build and tests remotely |
| NAOME harness/docs | `.naome/**`, `.naomeignore`, `AGENTS.md`, `docs/naome/**` | `naome-harness-health`, `repository-quality-check`, `repository-semantic-check`, `architecture-fitness-check`, `diff-check` |
| AI/API/subscription/payment work | future API, auth, entitlement, payment, subscription, usage, and premium paths | `xcode-build-ios-simulator`, targeted tests, `repository-quality-check`, `repository-semantic-check`, `architecture-fitness-check`, `diff-check`, and human review |

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
- `.github/workflows/ci.yml`
- Command: `npm ci`
- Command: `xcodebuild -list -project Noma.xcodeproj`
- Command: `xcodebuild -project Noma.xcodeproj -scheme Noma -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /private/tmp/noma-derived-data build`
- User confirmation on 2026-05-15: PR build must pass; default simulator is the
  latest available `iPhone 17 Pro`.
- XcodeBuildMCP simulator listing on 2026-05-15: `iPhone 17 Pro` available;
  verification commands use the portable simulator name rather than a local
  simulator id.

## Open Questions

- Define targeted test plans when OpenAI API, subscription, payment, premium
  entitlement, or API usage features are introduced.

## Rules

- Mirror durable entries in `.naome/verification.json`.
- Use only commands proven by repository files, CI, or user confirmation.
- Report exact commands and results. Do not claim proof that did not run.

## UI Contract

`.naome/ui-contract.json` is intentionally passive until Noma has real SwiftUI
design-system symbols. Do not add template token or component names that do not
compile in the app. Once those app symbols exist, register their token ids,
component ids, and UI style rules here before feature UI work depends on them.

### First-Run iOS/SwiftUI Bootstrap

1. Open `.naome/ui-contract.json` and replace template token/component names
   with the repository's real SwiftUI design-system names. This project-owned
   contract file is editable when the active task scope includes it.
2. Confirm the app exposes matching Swift symbols for the listed typography,
   spacing, radius, color, and component ids before feature UI work starts.
3. Before creating or editing a SwiftUI file, run
   `node .naome/bin/naome.js task preflight --path <SwiftUI path> --json` and
   follow the returned UI scope hints and `ui-style-check` command.
4. After a targeted edit, use
   `node .naome/bin/naome.js ui check --path <SwiftUI path> --json` for
   diagnosis before recording task proof.
5. For active task proof, run
   `node .naome/bin/naome.js task run-check --check ui-style-check --record-proof --json`.
   This records the check receipt that `agent-snapshot` and `commit-preflight`
   require.
6. Refresh `node .naome/bin/naome.js task agent-snapshot --json` to confirm the
   recorded proof and next action, then finish with
   `node .naome/bin/naome.js task commit-preflight --json`.
7. If no SwiftUI paths are selected or changed, the UI contract remains
   informational and must not block non-iOS work.
