# Status Report - 2026-03-12

## Branch and CI
- Active branch: `codex/ios-foundation`
- Latest completed work now extends beyond `59fe341` and includes setup-corridor guidance, explicit landmark roles, and role-aware handoff gating.
- Latest completed work now extends beyond `59fe341` and includes setup-corridor guidance, explicit landmark roles, role-aware handoff gating, and a checklist-driven venue capture routine.
- Latest completed work now also includes explicit re-entry zone guidance tied to the venue’s strongest setup corridor, so planning can review a concrete parent handoff route.
- The saved planner flow now also includes a persistent handoff-route review step, so start and recovery zones can be corrected even after the scan itself is finished.
- The current UX pass is also simplifying the visible workflow so task screens behave more like focused tools and less like mixed planning/debug dashboards.
- Repo-side signing is now configured for first device testing with Team ID `2924T28WXJ` and bundle ID `com.kanavin.armyra`.
- GitHub Actions is green on the latest run:
  - `23009941554` for commit `59fe341`
  - Workflow currently runs Swift package tests, generates the Xcode project with XcodeGen, builds the iOS simulator app, captures simulator screenshots for the main flows, exports them from the UI-test result bundle, and uploads both the app artifact and PNG screenshots.

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
  - See a capture routine with completed and pending steps plus a single next-best action for the club rep
  - See a re-entry plan that spells out the primary start zone, backup recovery zone, and whether those choices align with the clearest setup corridor through the venue
  - Review and override the saved handoff route directly from planning, not only while a scan session is active
  - Keep import/export on the `Projects` surface instead of showing it during every planning and chalking task
  - See planning framed as a step flow rather than a flat stack of equally weighted cards
  - Get a run-focused chalking screen once a session starts, with setup details moved behind the active execution state
  - Get warned if the chosen start/recovery edges are not backed by the corresponding tagged landmarks
  - See when captured landmarks are too clustered around one part of the venue to make a robust handoff
  - Get a concrete next-capture suggestion when landmark spread is weak, such as capturing a durable reference on another side of the venue
  - Get a durability hint when capture variety is weak, such as preferring a fence, building, or light post next
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
- CI / verification:
  - Screenshot automation now captures `Projects`, `Planning`, venue-scan, chalking preflight, and active chalking screens from the iOS simulator
  - Screenshot export is now part of the normal CI verification path rather than a manual debugging add-on
  - These screenshots are published as GitHub Actions artifacts so UI review is possible without a local Mac build

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
- Physical iPhone validation
- More balanced capture guidance so the rep can tell when too many landmarks are doing double duty as handoff edges instead of general references

## Recommended next step after context compaction
Keep tightening the club-side handoff quality:
- Let the rep review and adjust the suggested start edge and backup recovery edge before locking the scan
- Add stronger multi-pitch practicality checks beyond overlap, especially around setup room and likely chalking lanes
- Continue replacing generic capture success with more operational `safe to hand off` criteria as device testing becomes possible
- Keep improving venue capture guidance so landmark roles, checklist steps, and recovery instructions reflect real field-day behavior, not only label heuristics
- Keep tightening the re-entry plan so the rep can hand over a route through the ground, not just two labeled edges
- Keep improving the saved-route review so route corrections remain obvious before a package is shared out

## Signing note
- Apple Developer enrollment is now active enough for repo-side signing configuration.
- `project.yml` is configured with:
  - `DEVELOPMENT_TEAM = 2924T28WXJ`
  - `PRODUCT_BUNDLE_IDENTIFIER = com.kanavin.armyra`
- The next step for real phone testing is still a Mac/Xcode pass so Apple can create or refresh the local provisioning assets and install to the iPhone directly.
