# Implementation Roadmap

## Current status
- Core geometry, template, validation, and package persistence exist and pass CI.
- A minimal SwiftUI app shell exists for `Projects`, `Planning`, and `Chalking`.
- GitHub Actions now runs package tests, generates the Xcode project, builds the iOS simulator app, and uploads the artifact.

## Active milestone: Planning workflow foundation
The current development focus is to move from a static preview app toward a usable planning workflow.

### In progress now
- Add layout creation helpers so the app can create pitch instances directly from templates.
- Add project export-preview support so package structure is inspectable during development before full share-sheet integration.
- Add planning UI controls for choosing a template, creating a layout, and reviewing enabled geometry.

### Next after this slice
- Add editable layout transforms and lock-mode controls.
- Add package import from a local file and project duplication flows.
- Add AR-facing abstractions for venue scanning, relocalization confidence, and chalking guidance state.

## Near-term milestones
### Milestone 1: Planning workspace
- Create, name, and inspect multiple layouts in one venue.
- Surface template dimensions, enabled markings, and placement-lock intent.
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