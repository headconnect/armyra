# Status Report - 2026-03-12

## Branch and CI
- Active branch: `codex/ios-foundation`
- Latest completed work now extends beyond `59fe341` and includes setup-corridor guidance, explicit landmark roles, and role-aware handoff gating.
- GitHub Actions is green on the latest run:
  - `23009941554` for commit `59fe341`
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
- Venue-scan metadata for named preferred start and recovery edges
- Landmark-role metadata and role-aware readiness scoring for explicit start-side, recovery-side, and general-reference capture
- Lightweight landmark-spread analysis so the planner can tell when all useful references are still clustered on one side of the ground

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
  - See the suggested preferred start edge and backup recovery edge during capture and after save
  - Review and change the suggested start/recovery edges before locking the scan
  - See practical chalking-lane warnings when adjacent pitches leave too little setup room
  - See a venue-level best-setup-corridor summary in the top-down planner
  - See guidance when the chosen start/recovery edges do not line up with the best venue approach direction
  - Tag captured landmarks as start-side candidates, recovery-side candidates, or general references
  - See a handoff checklist showing whether the scan includes explicit start-side, recovery-side, and general-reference landmarks
  - Get warned if the chosen start/recovery edges are not backed by the corresponding tagged landmarks
  - See when captured landmarks are too clustered around one part of the venue to make a robust handoff
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
- More balanced capture guidance so the rep can tell when too many landmarks are doing double duty as handoff edges instead of general references

## Recommended next step after context compaction
Keep tightening the club-side handoff quality:
- Let the rep review and adjust the suggested start edge and backup recovery edge before locking the scan
- Add stronger multi-pitch practicality checks beyond overlap, especially around setup room and likely chalking lanes
- Continue replacing generic capture success with more operational `safe to hand off` criteria as device testing becomes possible
- Keep improving venue capture guidance so landmark roles and recovery instructions reflect real field-day behavior, not only label heuristics

## Signing note
- Apple Developer enrollment appears to be in progress, but the repo is ready for the next signing step once a real Team ID is available.
- When that is available, update `project.yml` with:
  - `DEVELOPMENT_TEAM`
  - a bundle identifier you control
