# Repository Structure

NAOME checks whether new and changed files land in a maintainable directory
structure. Existing structure debt stays visible in reports and cleanup routes,
but normal feature work is blocked only by relevant changed paths.

## Model

The structure model classifies each path as:

`path -> role -> module -> layer -> language -> generated/debt/changed`

Generic roles are `source`, `test`, `docs`, `config`, `script`, `generated`,
`artifact`, `dependency/vendor`, and `unknown`.

## Gates

- `naome quality check --changed` includes structure checks.
- `naome quality report` shows structure debt with other quality findings.
- `naome structure report --json` returns only structure findings.
- `naome structure explain --path <path> --json` explains one path's role,
  module, layer, language, generated flag, debt flag, and changed flag.
- `naome cleanup plan` and `naome cleanup route --path <path>` include
  structure findings when a cleanup task should move or split files.

## Checks

Structure checks include directory role mixing, misplaced file roles,
root-level file sprawl, dumping-ground directories, directory size, path depth,
case-insensitive path collisions, and source/test pairing hints.

Dumping-ground names such as `utils`, `helpers`, `common`, `shared`, `misc`,
and `lib` are not banned. New feature logic there is reported when a named
module location is more appropriate.

## Adapters

The core is language-independent. Adapters add deterministic signals for stack
conventions. Built-in adapters currently include `rust`,
`javascript-typescript`, `swift`, `xcode`, `xctest`, `swiftui`,
`ios-app-structure`, `swift-package`, `ios-resources`, and `generated-ios`.
Future adapters can add source roots, test roots, module roots, and allowed
root files without changing gate behavior.

If the repository later adds a new stack, `quality check --changed` and
`quality report` emit `adapter-policy-stale` until
`naome quality reconcile --write` updates the committed quality and structure
policy files.

## Local Policy

Rules live in `.naome/repository-structure.json`. Product defaults contain no
repository-specific paths. Local policy may add source roots, test roots,
generated roots, allowed root files, directory role rules, and layer rules.

Use local policy to document real repository conventions, not to grant special
rights to one product or hide cleanup work. Loosening a structure rule to pass a
feature diff requires human review.
