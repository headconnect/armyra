# Implementation Roadmap

## Current status
- Core geometry, template, validation, and package persistence exist and pass CI.
- A minimal SwiftUI app shell exists for `Projects`, `Planning`, and `Chalking`.
- GitHub Actions now runs package tests, generates the Xcode project, builds the iOS simulator app, and uploads the artifact.
- The planning workspace can now create layouts from templates, inspect export payloads, and edit selected layout dimensions, offsets, rotation, and lock mode.

## Active milestone: Planning workflow foundation
The current development focus is to move from a static preview app toward a usable planning workflow.

### In progress now
- Add package import from a local file and project duplication flows.
- Add naming and internal-marking editing controls for each selected layout.
- Add a clearer venue-level workspace summary that shows overlap and fit considerations.

### Next after this slice
- Add AR-facing abstractions for venue scanning, relocalization confidence, and chalking guidance state.
- Connect export preview to iOS-native sharing and Files integration.
- Add visual top-down placement previews to make rotation and offsets easier to reason about.

## Near-term milestones
### Milestone 1: Planning workspace
- Create, name, and inspect multiple layouts in one venue.
- Surface template dimensions, enabled markings, and placement-lock intent.
- Edit selected layout dimensions, offsets, rotation, and lock mode.
- Preview exportable package content from inside the app.

### Milestone 2: Package exchange
- Import and export `*.armyrafield` files.
- Validate schema versioning and incompatible package handling.
- Connect export UI to iOS share sheet and Files integration.

### Milestone 3: AR services
- Introduce a venue scan service abstraction that can later wrap `ARKit`/`ARWorldMap`.
- Model tracking confidence and relocalization hints in a way the chalking UI can react to.
- Keep AR-specific persistence isolated from app-domain package models.

## Working assumptions
- The app remains iPhone-first and offline-first.
- Precision and recovery UX matter more than survey-grade measurement.
- Docs in `docs/` should track both long-term plan and current implementation milestone so development decisions stay anchored.
