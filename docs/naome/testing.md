# Testing And Verification

Status: Uninitialized

## Verification Map

| Change type | Required proof | Command | Notes |
|---|---|---|---|
| NAOME baseline | Built-in harness proof | See Known Checks | Seeded by installer; extend during first-run intake. |
| Repository-specific work | Unknown | Unknown | Fill during first-run intake. |

## Early Feedback

After writing or heavily editing a file, run
`node .naome/bin/naome.js quality check --path <path>` for immediate
touched-file feedback. This catches local size, symbol, duplicate, structure,
and stale-policy issues before the task grows. It does not replace the final
`repository-quality-check`; always run the changed-file gate before completion.

## Known Checks

| Check id | Command | Cwd | Cost | Last verified |
|---|---|---|---|---|
| diff-check | `git diff --check` | `.` | fast | null |
| naome-harness-health | `node .naome/bin/check-harness-health.js` | `.` | fast | null |
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
| Unknown | Unknown | Unknown |

## Release Gates

| Check id | Required when |
|---|---|
| Unknown | Before release, when applicable. |

## Evidence

- `.naome/verification.json`
- `.naome/ui-contract.json`
- `.naome/bin/check-harness-health.js`
- `.naome/bin/check-task-state.js`
- `.naome/task-contract.schema.json`
- `docs/naome/architecture-fitness.md`

## Rules

- Mirror durable entries in `.naome/verification.json`.
- Use only commands proven by repository files, CI, or user confirmation.
- Preserve the JSON keys from `.naome/verification.json`.
- When intake is complete, set verification `status` to `ready`.
- Use only costs: `fast`, `medium`, `slow`, `expensive`, `ci-only`, `unknown`.
- Use dates as `YYYY-MM-DD` or `null`.
- Keep instruction files under 200 lines. `.naome/verification.json` is machine
  state instead; keep it schema-valid and bounded to 20 checks, 12 change types,
  and 12 release gates.
- Store long command output as a compact summary that preserves command, cwd,
  exit code, relevant lines, affected paths, and artifacts.
- When intake defines change types, include `repository-quality-check`,
  `repository-semantic-check`, and `architecture-fitness-check` as required
  checks for source, structure, documentation, harness, template, and CI
  changes.
- Before completion, select proof from the Verification Map when possible.
- Report exact commands and results. Do not claim proof that did not run.

## UI Contract

`.naome/ui-contract.json` defines platform profiles, token ids, component ids,
and rule ids for UI style checks. The built-in `ios-swiftui` profile is passive
until Swift files are selected or changed. Findings from `ui-style-check` use
stable `ruleId`, `suggestedTokenIds`, `suggestedComponentIds`, and `reasonCode`
fields so agents can repair only the affected paths.

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
