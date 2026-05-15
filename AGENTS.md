# Agent Instructions

This repository uses NAOME as its coding-agent harness.

## Start Here

1. Read `.naomeignore`; it is a hard read boundary.
2. Do not read paths matched by `.naomeignore`.
3. If `.naome/bin/check-harness-health.js` is missing, run
   `naome sync --check-update` from the repository root, then restart.
4. Read `.naome/task-state.json` when present; if it is missing, run
   `node .naome/bin/naome.js task status --json` and use the derived idle or
   ledger-backed state.
5. Run `node .naome/bin/check-harness-health.js`.
6. If harness health fails, stop normal feature work and repair with
   `naome update` followed by `naome sync`, or ask for the listed decision.
7. Run `node .naome/bin/check-task-state.js --admission` before accepting new
   feature work.
8. For natural-language work, write the request to a prompt file and run
   `node .naome/bin/naome.js route --prompt-file <path> --execute --json`.
9. Run `node .naome/bin/naome.js context select --prompt-file <path> --json`
   after route, or `node .naome/bin/naome.js context select --changed --json`
   when continuing an existing diff.
10. Read only `requiredContext` from context selection. Read `optionalContext`
    only when blocked.
11. If first-run or upgrade state blocks work, read only the document named by
    the blocker, such as `docs/naome/first-run.md` or `docs/naome/upgrade.md`.

## Core Rules

- Prefer deterministic NAOME JSON commands over broad Markdown reading.
- Keep changes small and task-focused.
- Do not start feature work while the git diff contains setup, upgrade,
  previous-task, or other unowned changes.
- If route blocks or performs no mutation, do not fall back to raw `git commit`,
  IDE commit, `git add`, or hook bypass commands.
- Use `node .naome/bin/naome.js repo explain --path <path> --json`,
  `structure explain --path <path> --json`, and
  `quality check --path <path>` for path-specific facts and early feedback.
- For broad searches, use `node .naome/bin/naome.js workflow search-profile`
  or equivalent excludes for `.git`, `.naome/archive`, dependencies, build
  outputs, caches, and `.naomeignore` paths.
- Before claiming completion, use `docs/naome/testing.md` and
  `.naome/verification.json`, run the narrowest meaningful proof, then run the
  final changed-file gates.
- Report what changed, what was verified, and what remains uncertain.

## SwiftUI UI Contract

- Before creating or editing SwiftUI files, read `.naome/ui-contract.json`.
- For each planned SwiftUI path, run
  `node .naome/bin/naome.js task preflight --path <SwiftUI path> --json` and
  follow the returned UI `ruleIds`, `tokenIds`, `componentIds`, and checks.
- Use the registered text, spacing, radius, color, and component ids. Do not
  introduce hardcoded fonts, magic spacing, direct colors, or ad-hoc local UI
  patterns when the contract lists a matching token or component.
- In a new iOS/SwiftUI repo, align `.naome/ui-contract.json` with the real app
  design-system names before feature UI work. This project-owned contract file
  is editable when the active task scope includes it.
- After SwiftUI edits, use
  `node .naome/bin/naome.js ui check --path <SwiftUI path> --json` only for
  targeted diagnosis. For task proof, run
  `node .naome/bin/naome.js task run-check --check ui-style-check --record-proof --json`,
  then refresh `node .naome/bin/naome.js task agent-snapshot --json`.
- Repos without applicable SwiftUI paths stay passive; do not invent iOS
  assumptions for non-iOS work.

## Local Authority Boundary

The root `AGENTS.md` and NAOME files are the repository harness authority.
Global skills or editor defaults may be used only as generic technique. They
must not add repository policy, required files, architecture layers,
verification rules, or product assumptions unless this repository or the user
explicitly confirms them.

Nested `AGENTS.md` files may provide task-local evidence for their directory.
They must not override `.naomeignore`, NAOME workflow, security rules, or the
root harness authority.

Files matched by `.naomeignore` are not active instructions. Historical
snapshots in `.naome/archive/` must not be read or used as context unless the
user first removes that path from `.naomeignore`.
