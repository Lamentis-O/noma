# Security And Risk

Status: Uninitialized

## Sensitive Areas

- Unknown.

## Secrets And Credentials

- Unknown.

## High-Risk Changes

- Unknown.

## Human Review Required

- Unknown.

## Evidence

- Unknown.

## Evidence Requirements

- Claims about credentialed automation, agent instruction files, skill
  directories, generated artifacts, or harness files require exact local
  evidence paths.
- Claims must not cite files matched by `.naomeignore`.

## NAOME Ignore Boundary

`.naomeignore` defines repository paths that agents must not read. The default
entry is `.naome/archive/` so historical snapshots never become active context.

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

## Agent Rules

- Do not expose secrets.
- Do not inspect paths matched by `.naomeignore`.
- Do not modify production credentials.
- Do not weaken auth, authorization, billing, data retention, or encryption
  without explicit user direction and verification.
