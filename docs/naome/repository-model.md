# Repository World Model

The repository model is the deterministic source for machine-readable facts
about this repository. It keeps stack and layout facts out of free-form
Markdown so agents can make repeatable decisions.

## Files

- `.naome/repository-model.json` stores canonical facts.
- `.naome/verification.json` stores runnable checks and change-type proof
  policy.
- Repository-quality and repository-structure policy store quality adapters and
  layout rules.
- Markdown documents explain workflow and summarize human context; they are not
  the primary store for build, stack, or path-role facts.

## Commands

- `naome repo model --write --json` refreshes the model from repository files.
- `naome repo check --json` verifies the committed model is current.
- `naome repo explain --path <path> --json` explains the role and language for a
  path using the canonical model.

## Facts

`naome.repository-model.v2` keeps the backward-compatible flat `facts[]` list
and adds typed world-model sections. `naome.repository-model.v1` remains
readable; new writes prefer v2.

Flat facts are deterministic records with stable ids:

- `language:<value>`
- `packageManager:<value>`
- `buildSystem:<value>`
- `sourceRoot:<path>`
- `testRoot:<path>`
- `docsRoot:<path>`
- `generatedRoot:<path>`
- `artifactRoot:<path>`
- `verificationCheck:<id>`

Each fact includes evidence paths and a source. Do not hand-edit generated facts
as normal workflow. Refresh them with the command above.

## World Sections

The v2 model stores typed sections so agents do not need to infer repository
shape from prose:

- `languages`, `packageManagers`, and `buildSystems`
- `adapters` detected from deterministic stack signals
- `roots` for source, test, docs, generated, and artifact paths
- `entities` for packages, apps, and modules
- `pathFacts` for significant paths with role, module, entity, language, and
  generated/artifact flags
- `verificationChecks` copied from `.naome/verification.json`

These sections are generic and adapter-extensible. Product defaults must not
contain repository-specific exceptions.

## Agent Rule

When a task depends on the stack, package manager, build system, source roots,
test roots, generated roots, or verification ids, read or refresh the repository
model instead of searching broad Markdown files. If the model is stale, update it
first, then continue with the task.

For a specific path, use:

```text
naome repo explain --path <path> --json
```

The explanation returns the canonical role, language, module, entity, matching
facts, and evidence for that path.

## Drift Gates

NAOME does not silently rewrite `.naome/repository-model.json` during normal
gates. Instead, stale facts are reported deterministically:

- `naome doctor --json` reports a stale repository model section.
- `node .naome/bin/check-task-state.js --progress` blocks active work until the
  model is refreshed.
- `naome quality check --changed --json` emits `repository-model-stale` as a
  changed-code finding.

The fix is explicit and idempotent:

```text
naome repo model --write --json
```
