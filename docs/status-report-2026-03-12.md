# Status Report - 2026-03-12

## Branch and CI
- Active branch: `codex/ios-foundation`
- Latest completed work is committed through `d145c30` (`Fix tracking asset persistence types`).
- GitHub Actions is green on the latest run:
  - `23000040031` for commit `d145c30`
  - Workflow currently runs Swift package tests, generates the Xcode project with XcodeGen, builds the iOS simulator app, and uploads the built app artifact.

## What exists now
### Core domain
- Pitch templates for 5/7/9/11-a-side
- Field geometry generation
- Layout validation
- Package persistence for `*.armyrafield`
- Layout analysis for bounding boxes and overlap detection
- Shared chalking session state and tracking confidence models
- AR boundary models for relocalization snapshots, local tracking assets, and diagnostics

### App shell
- `Projects` tab:
  - Select project
  - Duplicate project
  - Preview export payload
  - Import/export package plumbing
- `Planning` tab:
  - Add layouts from templates
  - Select a layout
  - Edit name, size, offsets, rotation, and lock mode
  - Toggle supported markings
  - View top-down placement preview
  - See basic overlap warnings
  - Run a mock venue-scan workflow
  - Save a local tracking asset
  - Inspect AR diagnostics for planning capture
- `Chalking` tab:
  - Select a layout for chalking
  - Start a mock chalking session
  - Advance segment progress
  - Cycle tracking confidence between `good`, `warning`, and `recover`
  - End session
  - Inspect venue-aware preflight and AR diagnostics before device testing

## Important files
- Product plan: `docs/ios-ar-football-pitch-plan.md`
- Ongoing roadmap: `docs/implementation-roadmap.md`
- This handoff snapshot: `docs/status-report-2026-03-12.md`
- App state: `ArmyraApp/ViewModels/ProjectStore.swift`
- Planning UI: `ArmyraApp/Views/PlanningView.swift`
- Planning preview: `ArmyraApp/Views/PlanningPreviewView.swift`
- Chalking UI: `ArmyraApp/Views/ChalkingView.swift`
- Mock tracking service: `ArmyraApp/VenueTrackingService.swift`
- AR coordinator boundary: `ArmyraApp/ARSessionCoordinator.swift`
- iOS ARKit adapter scaffold: `ArmyraApp/ARKitSessionCoordinator.swift`
- Local tracking asset persistence: `ArmyraApp/LocalVenueTrackingAssetStore.swift`
- Core geometry/persistence: `Sources/ArmyraCore/`

## Current architectural direction
- The app is intentionally in a `pre-AR workflow foundation` phase.
- Planning and chalking flows are being made realistic first, while AR-specific behavior is being isolated behind service abstractions that already compile on iOS.
- Package models remain app-domain-first so AR persistence can evolve separately from sharing/import/export.
- Local relocalization assets are now intentionally file-backed and kept outside the exported package.

## What is still missing
- Real venue scanning UX that continuously reflects `ARKit` session state
- Real tracking source behind chalking guidance instead of mock segment progression
- iOS-native share sheet polish beyond file export plumbing
- Device signing configuration in `project.yml`
- Physical iPhone validation

## Recommended next step after context compaction
Drive the first real phone-testing pass:
- Surface AR session diagnostics and asset information in the UI
- Verify that a planning scan actually captures a local world map payload
- Confirm that chalking startup can read and reuse that payload for relocalization
- After that, begin replacing mock chalking progression with live AR-driven guidance state

## Signing note
- Apple Developer enrollment appears to be in progress, but the repo is ready for the next signing step once a real Team ID is available.
- When that is available, update `project.yml` with:
  - `DEVELOPMENT_TEAM`
  - a bundle identifier you control
