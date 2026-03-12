# Status Report - 2026-03-12

## Branch and CI
- Active branch: `codex/ios-foundation`
- Latest completed work is committed through `8ef33ca` (`Add handoff readiness and chalk path previews`).
- GitHub Actions is green on the latest run:
  - `23003603489` for commit `8ef33ca`
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
- Venue-scan readiness analysis for club-side capture robustness and handoff gating

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
  - See a club-facing capture gate with `lock for handoff` versus `save draft anyway`
  - Save a local tracking asset
  - Inspect AR diagnostics for planning capture
  - See a handoff-oriented readiness summary for parent-safe chalking
  - Preview the chalk path sequence for the selected layout, including the field-day start reference
- `Chalking` tab:
  - Select a layout for chalking
  - Start a mock chalking session
  - Advance segment progress
  - Cycle tracking confidence between `good`, `warning`, and `recover`
  - End session
  - Inspect venue-aware preflight and AR diagnostics before device testing
  - See recent AR diagnostics history
  - See named current/upcoming chalk segments instead of only aggregate progress
  - See a whole-pitch preview with active line, start cue, and recovery target markers

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
- The app is intentionally shifting from a general `pre-AR workflow foundation` into a `field-day UX` phase.
- Planning and chalking flows are being made trustworthy first, while AR-specific behavior remains isolated behind service abstractions that already compile on iOS.
- Package models remain app-domain-first so AR persistence can evolve separately from sharing/import/export.
- Local relocalization assets are now intentionally file-backed and kept outside the exported package.

## What is still missing
- Real venue scanning UX that continuously reflects `ARKit` session state
- Real tracking source behind chalking guidance instead of mock segment progression
- iOS-native share sheet polish beyond file export plumbing
- Device signing configuration in `project.yml`
- Physical iPhone validation
- More explicit club-side guidance about where the strongest start edge and backup recovery edge physically are on the ground

## Recommended next step after context compaction
Keep tightening the parent-facing execution loop:
- Add stronger planner validation around low-confidence venue scans and impractical pitch spacing
- Make the chalking view communicate start/recovery/active-line context even more clearly than the current text-plus-preview approach
- Continue replacing manual chalking progression with live AR-driven guidance state as device testing becomes possible

## Signing note
- Apple Developer enrollment appears to be in progress, but the repo is ready for the next signing step once a real Team ID is available.
- When that is available, update `project.yml` with:
  - `DEVELOPMENT_TEAM`
  - a bundle identifier you control
