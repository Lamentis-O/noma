# Architecture

Status: Partial

## Observed Structure

- `NomaApp` is the SwiftUI app entry point and presents `ContentView`.
- `ContentView` currently contains the starter SwiftUI view.
- Assets live under `Noma/Assets.xcassets`.
- Unit tests and UI tests are separate Xcode targets.
- npm tooling is repository-level and currently exists to install NAOME.

## Known Boundaries

- Keep application source in `Noma/`.
- Keep authentication shell UI and state in `Noma/Features/Auth/`.
- Keep Apple/Supabase integration adapters in `Noma/Services/`.
- Keep unit tests in `NomaTests/` and UI tests in `NomaUITests/`.
- Keep Xcode project configuration in `Noma.xcodeproj/`.
- Keep NAOME harness state in `.naome/` and NAOME docs in `docs/naome/`.
- Do not read or use paths matched by `.naomeignore`.
- `node_modules/` is local dependency output and is ignored.

## Assumed Boundaries

- No app-specific feature modules exist yet.
- No durable design system exists yet; SwiftUI UI work should first align
  `.naome/ui-contract.json` with real project tokens and components.

## Dependency Rules

- App source depends on SwiftUI and AuthenticationServices for native Apple SSO.
- Supabase client access is centralized behind `SupabaseClientProvider`; iOS
  code must use publishable client keys only and must not include service-role
  or secret keys.
- `@lamentis/naome` is repository tooling, not app runtime code.

## Auth Shell

- The app starts through `RootView`, which routes `loading`, `signedOut`, and
  `signedIn` states.
- `AuthStateManager` owns initial session loading, auth state observation, and
  Apple sign-in actions.
- The first subscription gate should sit after authentication and before
  premium app content. No profile table, subscription schema, or entitlement
  logic belongs to the initial auth shell.

## Generated Or External Code

- Xcode build products and DerivedData are generated output and should remain
  outside commits.
- `node_modules/` is generated dependency output and should remain outside
  commits.
- NAOME machine-owned files should be refreshed through `naome sync`.

## Evidence

- `Noma/NomaApp.swift`
- `Noma/ContentView.swift`
- `Noma/Features/Auth/AuthStateManager.swift`
- `Noma/Features/Auth/RootView.swift`
- `Noma/Services/Supabase/SupabaseClientProvider.swift`
- `Noma/Assets.xcassets/Contents.json`
- `NomaTests/NomaTests.swift`
- `NomaUITests/NomaUITests.swift`
- `NomaUITests/NomaUITestsLaunchTests.swift`
- `Noma.xcodeproj/project.pbxproj`
- `package.json`
- `.gitignore`
- `.naomeignore`
- `.naome/repository-model.json`
- `.naome/ui-contract.json`

## Open Architecture Questions

- What are the intended app features and domain boundaries?
- Should the app use a dedicated design system before significant UI work?
