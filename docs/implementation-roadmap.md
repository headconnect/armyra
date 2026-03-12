# Implementation Roadmap

## Current status
- Core geometry, template, validation, and package persistence exist and pass CI.
- A minimal SwiftUI app shell exists for `Projects`, `Planning`, and `Chalking`.
- GitHub Actions now runs package tests, generates the Xcode project, builds the iOS simulator app, and uploads the artifact.
- The planning workspace can now create layouts from templates, inspect export payloads, and edit selected layout dimensions, offsets, rotation, and lock mode.
- The app now has basic `*.armyrafield` import/export plumbing and project duplication support, which moves it closer to real device testing once Apple signing is configured.
- The planning screen now includes a top-down layout preview and basic overlap detection so placement changes can be reasoned about without AR.
- The chalking screen now runs against a mock tracking/session model with progress and confidence states, which gives us a non-AR path to exercise the future trolley workflow.
- The planning screen now also includes a mock venue-scan workspace so landmark capture, coverage progression, and scan locking can be exercised before real camera-based scanning exists.

## Active milestone: Pre-AR workflow foundation
The current development focus is to make planning and chalking flows realistic before wiring in real `ARKit` services.

### In progress now
- Add a clearer venue-level workspace that connects planning edits, venue scanning, and future relocalization.
- Prepare the app shell for signed iPhone deployment by keeping import/export and planning flows independent of simulator-only behavior.
- Introduce mockable scanning, tracking, and relocalization services so the workflow can be exercised without camera-based AR.

### Next after this slice
- Add AR-facing abstractions for venue scanning, relocalization confidence, and chalking guidance state.
- Connect export preview to iOS-native sharing and Files integration.
- Add visual top-down placement previews to make rotation and offsets easier to reason about.

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

### Milestone 3: AR services
- Introduce a venue scan service abstraction that can later wrap `ARKit`/`ARWorldMap`.
- Model tracking confidence and relocalization hints in a way the chalking UI can react to.
- Keep AR-specific persistence isolated from app-domain package models.
- Swap the mock scan and chalking services for real implementations once landmark scanning and relocalization are ready.

## Working assumptions
- The app remains iPhone-first and offline-first.
- Precision and recovery UX matter more than survey-grade measurement.
- Docs in `docs/` should track both long-term plan and current implementation milestone so development decisions stay anchored.
