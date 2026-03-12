# Status Report - 2026-03-12

## Branch and CI
- Active branch: `codex/ios-foundation`
- Latest completed work is committed through `2b41fa3` (`Add mock chalking session flow`).
- GitHub Actions is green on the latest run:
  - `22996310565` for commit `2b41fa3`
  - Workflow currently runs Swift package tests, generates the Xcode project with XcodeGen, builds the iOS simulator app, and uploads the built app artifact.

## What exists now
### Core domain
- Pitch templates for 5/7/9/11-a-side
- Field geometry generation
- Layout validation
- Package persistence for `*.armyrafield`
- Layout analysis for bounding boxes and overlap detection
- Shared chalking session state and tracking confidence models

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
- `Chalking` tab:
  - Select a layout for chalking
  - Start a mock chalking session
  - Advance segment progress
  - Cycle tracking confidence between `good`, `warning`, and `recover`
  - End session

## Important files
- Product plan: `docs/ios-ar-football-pitch-plan.md`
- Ongoing roadmap: `docs/implementation-roadmap.md`
- App state: `ArmyraApp/ViewModels/ProjectStore.swift`
- Planning UI: `ArmyraApp/Views/PlanningView.swift`
- Planning preview: `ArmyraApp/Views/PlanningPreviewView.swift`
- Chalking UI: `ArmyraApp/Views/ChalkingView.swift`
- Mock tracking service: `ArmyraApp/VenueTrackingService.swift`
- Core geometry/persistence: `Sources/ArmyraCore/`

## Current architectural direction
- The app is intentionally in a `pre-AR workflow foundation` phase.
- Planning and chalking flows are being made realistic first, while AR-specific behavior is being isolated behind future service abstractions.
- Package models remain app-domain-first so AR persistence can be swapped or expanded later without destabilizing sharing/import/export.

## What is still missing
- Real `ARKit` venue scanning and relocalization
- Real tracking source behind chalking mode
- iOS-native share sheet polish beyond file export plumbing
- Device signing configuration in `project.yml`
- Physical iPhone validation

## Recommended next step after context compaction
Implement the AR service boundary:
- Add venue scan/relocalization protocols and app-facing state models
- Add a mock `VenueScanService` plus a placeholder scan UI
- Refactor the current mock chalking tracking service to conform to the same service-oriented architecture that a real `ARKit` implementation will use later

## Signing note
- Apple Developer enrollment appears to be in progress, but the repo is ready for the next signing step once a real Team ID is available.
- When that is available, update `project.yml` with:
  - `DEVELOPMENT_TEAM`
  - a bundle identifier you control
