# Repository Quality

NAOME keeps legacy debt visible without blocking unrelated feature work.

## Gates

- `naome quality check --changed` blocks only on files changed in the current
  diff. If a legacy file is touched, that file must satisfy the configured
  quality and semantic changed rules before commit.
- `naome quality check --path <path>` is the early touched-file gate. Run it
  immediately after editing a file to catch file length, diff growth, function
  length, top-level symbol count, same-file duplicate regions, structure
  issues, and stale adapter/model policy before a large task accumulates.
  Repeat `--path` for a small touched set. This is a fast local feedback gate;
  the final `--changed` gate still remains required.
- `naome semantic check --changed` is also exposed as the explicit semantic
  changed gate. Fresh verification profiles require it next to
  `repository-quality-check`; `quality check --changed` includes the same
  semantic changed findings for backward compatibility with older profiles.
- `naome quality report` scans the repository with normal budgets and reports
  debt without failing feature work. Full repository duplicate,
  near-duplicate, and semantic grouping checks are deep-only.
- `naome quality report --deep` runs the intentionally expensive full
  repository checks.
- `naome cleanup plan` groups report findings into deterministic cleanup tasks.
- `naome cleanup route --path <path>` returns agent instructions for one file.
  Structure findings include rule-specific guidance such as moving misplaced
  tests, pairing source with nearby tests, splitting dumping-ground folders, or
  resolving case collisions.

## Configuration

Repository-specific rules live in `.naome/repository-quality.json`.

`quality init` writes only policy files and an empty baseline placeholder. It
does not deep-scan the repository. To record existing debt intentionally, run
`quality init --baseline`; use `quality init --deep-baseline` only when broad
duplicate and semantic grouping checks are expected.

`quality init` selects deterministic built-in adapters from repository files.
Adapters are plug-and-play profiles such as `rust` or
`javascript-typescript`. They add stack-specific ignored/generated paths and
path rules at runtime without hard-coding a specific product repository into
the generic template.

Repository stacks can change after setup. `quality check --changed` and
`quality report` compare current repository signals with committed
`enabledAdapters`; when a new stack is present but not enabled, they emit
`adapter-policy-stale`. Use `naome quality reconcile --json` to inspect the
delta and `naome quality reconcile --write` to update
`.naome/repository-quality.json` and `.naome/repository-structure.json`
deterministically. Do not hand-edit adapter lists as the normal path.

Built-in adapter detection is path/manifest based and deterministic:

- `rust`: `Cargo.toml` or `.rs` files.
- `javascript-typescript`: `package.json` or JS/TS files.
- `swift`: `Package.swift` or `.swift` files.
- `xcode`: `.xcodeproj` or `.xcworkspace` content.
- `xctest`: Swift test targets such as `Tests`, `*Tests`, or `*UITests`.
- `swiftui`: SwiftUI-style app/view paths such as `*App.swift`,
  `*View.swift`, `Views`, or Preview Content.
- `ios-app-structure`: iOS app entrypoints, `Info.plist`, entitlements, or
  asset catalogs.
- `swift-package`: Swift Package Manager `Sources` and `Tests` layout.
- `ios-resources`: `.xcassets`, `.strings`, `.plist`, `.storyboard`, `.xib`,
  and entitlements.
- `generated-ios`: SwiftGen, Sourcery, protobuf, and `*.generated.swift`
  outputs.

Local `pathRules` are project overrides, not product defaults. They may document
repo-specific debt or special file roles, but loosening a rule to pass a feature
diff requires human review.

The scanner has three modes:

- `PathScoped`: explicitly requested touched files are read fully, with the
  repository path index used for path/structure context. It avoids fully
  analyzing unrelated changed files, making it suitable directly after file
  writes.
- `ChangedFast`: changed files are read fully; unchanged files may contribute
  cached facts for duplicate comparison.
- `Report`: repository-wide, budgeted debt visibility. If budgets are hit, JSON
  sets `summary.truncated` and includes stable `reasonCodes`.
- `DeepReport`: explicit expensive scan for full duplicate, near-duplicate, and
  semantic grouping work.

Per-file analysis facts are cached under `.naome/cache/quality/`. Cache entries
are local-only, keyed by NAOME version, config hash, adapter version, path, and
content hash. Cache corruption or misses cause a rescan, not a gate failure.
Use `quality cache status --json` and `quality cache clear` for maintenance.

The default scanner is language-agnostic and uses text plus symbol heuristics:
file length, diff growth, function or component length, top-level symbol count,
duplicate regions, and near-duplicate functions. Duplicate regions are grouped
to avoid overlapping window spam and include repeated regions inside the same
file. Near-duplicate function checks compare functions/components, not
container symbols against their own children.

Structure checks run through the same gate. See `repository-structure.md` for
path roles, module/layer policy, adapters, and cleanup routing.

Agents may propose stricter repo-specific rules after inspecting the language
and stack.

## Semantic Cleanup

Some maintainability debt is semantic rather than purely syntactic. Examples
include inline legacy compatibility fixtures, copied config objects, stale test
builders, hand-written schema snapshots, and helper data that should move into a
shared factory after enough call sites accumulate.

NAOME detects these with a generic semantic-cleanup layer instead of hard-coding
product paths or deleting compatibility fixtures opportunistically. The model
is:

- detect repeated object shapes, schema literals, fixture builders, and config
  snapshots across changed and report-mode files;
- classify each finding as `legacy fixture`, `duplicated fixture`,
  `schema snapshot`, `generated metadata`, or `inline builder`;
- keep existing report-mode debt visible without blocking unrelated work;
- block changed/new semantic debt through `quality check --changed` and
  `semantic check --changed`;
- route cleanup to extract a shared fixture, builder, schema writer, or generated
  metadata refresh command;
- preserve behavior by requiring tests before removing or consolidating legacy
  compatibility fixtures.

Semantic cleanup is a scout and gate, not an auto-fixer:

- `naome semantic report --json` runs a budgeted semantic report.
- `naome semantic report --deep --json` runs repo-wide semantic grouping.
- `naome semantic check --changed --json` checks only changed semantic debt for
  gate use.
- `naome semantic route --finding <id> --json` gives an agent the complete
  affected path list, cleanup intent, and required checks for one finding group.
- `naome semantic loop --json` selects the next deterministic cleanup action:
  changed-code findings first, then report-only legacy debt.

## Baseline

Existing debt is recorded in `.naome/repository-quality-baseline.json` by
`naome quality init --baseline` or `naome quality init --deep-baseline`.
Baseline debt remains visible in reports, but only changed files are blocking
during feature work.
