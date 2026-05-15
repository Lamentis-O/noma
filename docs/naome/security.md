# Security And Risk

Status: Partial

## Sensitive Areas

- No authentication, customer data, network clients, billing, persistence, or
  production configuration were found during intake.
- Xcode signing settings and provisioning profiles can become sensitive when
  distribution is added.
- npm package changes can affect repository tooling and should preserve the
  lockfile.

## Secrets And Credentials

- No repository secret files were found during intake.
- Do not commit local Xcode credentials, provisioning profiles, npm tokens, or
  environment files if they are introduced later.

## High-Risk Changes

- Adding auth, payments, data storage, networking, or telemetry.
- Changing bundle identifiers, signing, entitlements, or deployment settings.
- Changing `.naomeignore`, NAOME harness files, or agent instructions.
- Changing npm dependencies without updating and reviewing `package-lock.json`.

## Human Review Required

- Any future auth, billing, secret handling, persistence, network, signing, or
  deployment work.
- Any change that weakens NAOME boundaries or asks agents to inspect ignored
  paths.

## Evidence

- `Noma.xcodeproj/project.pbxproj`
- `Noma/NomaApp.swift`
- `Noma/ContentView.swift`
- `package.json`
- `package-lock.json`
- `.gitignore`
- `.naomeignore`
- `AGENTS.md`

## NAOME Ignore Boundary

`.naomeignore` defines repository paths that agents must not read. Current
ignored paths are `.naome/archive/`, `.naome/cache/`, and `.naome/tasks/`.

Rules:

- Read `.naomeignore` before inspecting repository files.
- Treat patterns as repository-root-relative, gitignore-like paths.
- Do not read, summarize, scan, import, or use ignored files as evidence.
- If ignored content seems necessary, ask the user to remove the path from
  `.naomeignore` before continuing.

## Harness Integrity Boundary

Machine-owned files in `.naome/manifest.json` are active harness controls.
Before feature work, run `node .naome/bin/check-harness-health.js`. Stop if it
reports missing files, symlinks, integrity drift, or a missing archive ignore
boundary. Git commits do not bless harness drift; machine-owned files must match
the packaged hashes embedded in the health checker. Repair only with the
installer or an explicit human decision.
