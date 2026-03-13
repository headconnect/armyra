# Implementation Roadmap

## Current status
- Core geometry, template, validation, and package persistence exist and pass CI.
- A minimal SwiftUI app shell exists for `Projects`, `Planning`, and `Chalking`.
- GitHub Actions now runs package tests, generates the Xcode project, builds the iOS simulator app, and uploads the artifact.
- GitHub Actions now also runs a screenshot UI-test pass, exports screenshot attachments from the simulator test result bundle, and uploads PNG screenshots of key app flows, so UI verification is possible without a local Mac build.
- The planning workspace can now create layouts from templates, inspect export payloads, and edit selected layout dimensions, offsets, rotation, and lock mode.
- The app now has basic `*.armyrafield` import/export plumbing and project duplication support, which moves it closer to real device testing once Apple signing is configured.
- The planning screen now includes a top-down layout preview and basic overlap detection so placement changes can be reasoned about without AR.
- The chalking screen now runs against a mock tracking/session model with progress and confidence states, which gives us a non-AR path to exercise the future trolley workflow.
- The planning screen now also includes a mock venue-scan workspace so landmark capture, coverage progression, and scan locking can be exercised before real camera-based scanning exists.
- The chalking screen now derives a venue-aware preflight from the saved scan so start hints, readiness, and recovery expectations reflect the planning work.
- The app now has an explicit AR boundary layer with relocalization snapshots and local tracking-asset records kept separate from the exported pitch package.
- The app now also has an iOS-only `ARKit` session coordinator stub behind the same protocol, so a real camera-backed implementation can replace the mock path incrementally.
- Local tracking assets now have a file-backed store and the `ARKit` coordinator starts planning/chalking sessions with `ARWorldTrackingConfiguration`, preparing the path toward real relocalization.
- Planning and chalking now surface AR diagnostics in the UI so device testing can verify session mode, saved asset presence, payload size, and last AR error without attaching a debugger.
- The chalking session now reconciles itself against relocalization state, so tracking confidence and progress can react to live AR status instead of depending only on manual simulation controls.
- Planning and chalking now keep a short diagnostics history, which should make on-device relocalization regressions and recoveries easier to spot during field testing.
- The chalking session now carries named guide segments, which lets the UI show the current chalk segment and the next few segments instead of only aggregate progress.
- Planning now produces a handoff-oriented readiness summary, and both planning and chalking can render a shared chalk-path preview with the active line highlighted in context.
- The shared chalk-path preview now also carries explicit start and recovery markers, pushing the parent UX closer to a glanceable field-day workflow instead of a diagnostics-first prototype.
- The venue scan workspace now has a club-facing capture gate that distinguishes `lock for handoff` from `save draft anyway`, with explicit issues around thin landmarks, one-sided coverage, and weak recovery setup.
- Venue scans now also carry a named preferred start edge and backup recovery edge, so the club rep is handing off a concrete setup plan rather than only a generic relocalization score.
- The planner can now review and change the suggested start/recovery edges before locking the scan, and readiness warns if both edges collapse to the same fallback.
- Planning now also checks for narrow practical chalking lanes between adjacent pitches, so the club sees real setup-risk warnings beyond simple overlap.
- Planning now also summarizes the best venue-level setup corridor across the whole arrangement, which starts to catch "no sensible approach lane through the ground" problems.
- Planning now compares the chosen handoff edges against the strongest setup corridor and warns when the rep appears to be sending parents in from the wrong side of the venue.
- The venue scan workflow now supports explicit landmark roles, so the club can tag captured objects as start-side candidates, recovery-side candidates, or general references.
- Venue-scan readiness now scores those landmark roles directly and shows a handoff checklist, so a scan is not considered parent-safe just because edge labels happen to exist.
- Venue-scan readiness now also checks that the chosen start and recovery edges are backed by correctly tagged landmarks, which reduces the risk of handoff drift from manual edge overrides.
- Venue-scan readiness now also checks whether captured landmarks are actually spread around the venue, which helps catch scans that look complete on paper but are still clustered on one side in practice.
- The planning workspace now turns poor landmark spread into an explicit next capture suggestion, so the rep gets a concrete “go capture the east/north side” style instruction instead of only a warning.
- The planning workspace now also suggests a better landmark type when capture quality is weak, nudging the rep toward durable references like fences, buildings, or light posts instead of repeated vague objects.
- The venue scan gate now also exposes a concrete capture routine with completed and pending steps plus a single next-best action, moving the club workflow closer to an operational checklist instead of a warning list.
- Planning readiness now also spells out a primary re-entry zone, a backup recovery zone, and whether those choices actually align with the strongest setup corridor across the venue.
- The planner now also exposes a persistent handoff-route review step, so the club can revisit and override the primary or backup re-entry zone even after a scan has been saved.
- The XcodeGen project is now preconfigured with Team ID `2924T28WXJ` and bundle ID `com.kanavin.armyra`, so the repo is ready for first-time device signing when opened in Xcode on a Mac.

## Active milestone: Field-day UX
The current development focus is to make the handoff from club rep to parent feel trustworthy, fast, and easy to follow before deepening the AR implementation.

### In progress now
- Strengthen planner-side readiness and validation so a saved package clearly communicates whether it is safe to hand to a first-time parent volunteer.
- Make chalking mode default to whole-pitch context, with the active line, start point, and recovery target all visible at a glance.
- Keep diagnostics available for device testing, but progressively demote them behind the operational guidance.

### Next after this slice
- Add clearer planner validation around practical spacing and low-confidence venue scans so `ready for chalking` means something operationally.
- Deepen the club capture checklist with more explicit re-entry zone language and stronger multi-pitch practicality checks before handoff.
- Keep turning venue capture into a checklist-first workflow so the club rep can follow a routine rather than interpreting scattered readiness warnings.
- Keep refining the re-entry zone plan so the club can hand parents a concrete approach path, not only a pair of labeled edges.
- Keep strengthening the post-scan route review so saved packages can still be corrected before they are handed to volunteers.
- Let the rep review and adjust the automatically suggested start/recovery edges before locking the scan.
- Use explicit landmark roles more directly in readiness scoring so handoff confidence depends less on label heuristics over time.
- Add role-aware capture guidance that nudges the rep toward a more balanced landmark spread, not just one start object and one fallback object.
- Keep improving the venue-side heuristics so spread warnings become less dependent on label wording once real scan metadata exists.
- Add a more venue-level notion of setup corridors or trolley approach lanes, not just pairwise pitch gaps.
- Keep turning chalking into a recovery-first workflow by surfacing recovery targets, start-edge cues, and trusted/not-trusted guidance states directly in the main UI.
- Feed more of the chalking progression from live AR status so the simulator controls become an escape hatch rather than the main interaction.

## Near-term milestones
### Milestone 1: Planning workspace
- Create, name, and inspect multiple layouts in one venue.
- Surface template dimensions, enabled markings, and placement-lock intent.
- Edit selected layout dimensions, offsets, rotation, and lock mode.
- Preview relative placement in a top-down planning view and surface simple overlap warnings.
- Preview exportable package content from inside the app.

### Milestone 2: Package exchange
- Import and export `*.armyrafield` files.
- Validate schema versioning and incompatible package handling.
- Connect export UI to iOS share sheet and Files integration.
- Once an Apple development team is configured in the project, validate package import/export and planning flows on a physical iPhone.
- Use a Mac/Xcode pass to complete the first direct iPhone install, since the repo-side signing values are now set but Apple still needs to mint local provisioning assets through Xcode.
- Keep CI screenshots current so planning and chalking UI regressions are visible even before device deployment is available.
- Treat CI screenshots as part of build verification, alongside package tests and simulator app builds, so visual regressions are caught in the same loop as functional breakages.

### Milestone 3: AR services
- Introduce a venue scan service abstraction that can later wrap `ARKit`/`ARWorldMap`.
- Model tracking confidence and relocalization hints in a way the chalking UI can react to.
- Keep AR-specific persistence isolated from app-domain package models.
- Swap the mock scan and chalking services for real implementations once landmark scanning and relocalization are ready, while preserving the parent-first chalking UX.

## Working assumptions
- The app remains iPhone-first and offline-first.
- Precision and recovery UX matter more than survey-grade measurement.
- Docs in `docs/` should track both long-term plan and current implementation milestone so development decisions stay anchored.
