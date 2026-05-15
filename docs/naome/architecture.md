# Architecture

Status: Uninitialized

## Observed Structure

- Unknown.

## Known Boundaries

- NAOME information falls into durable project state, generated projection,
  local runtime state, run evidence, and product source.
- Durable project state is committed repository or package state needed to
  reinstall or reconstruct the harness.
- `.naome/task-state.json` is the local generated task-state projection.
- `.naome/tmp/` and `.naome/tasks/` are local runtime state and must not be
  committed.
- Per-check proof files are local run evidence. Prefer compact proof batches in
  the local task-state projection when many release checks share the same
  evidence paths.
- Prompt routing uses fenced `naome-prompt-envelope-v1` JSON envelopes as the
  deterministic routing input. Raw natural-language prompts are audit text and
  must not be treated as workflow authority until an agent normalizes them into
  canonical fields such as `requestKind`, `mutationIntent`,
  `publicationIntent`, `requestedActions`, `workflowAction`, `taskIntent`, and
  `risk`. Legacy `naome-intent-v2` envelopes are not supported. Unknown
  envelope values require prompt normalization, conflicting fields block as
  ambiguous, and `referencedPaths` is the primary context-selection source for
  prompt-mentioned files.

## Assumed Boundaries

- Unknown.

## Dependency Rules

- Unknown.

## Generated Or External Code

- Generated NAOME projections must be reproducible from durable state.

## Evidence

- Unknown.

## Evidence Requirements

- Claims about generated artifacts, harness files, skill directories, or
  automation policy require exact local evidence paths.

## Open Architecture Questions

- Which modules or directories are authoritative boundaries?
- Which shortcuts should agents avoid?
