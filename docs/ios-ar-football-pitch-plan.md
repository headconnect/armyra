# iOS AR Football Pitch Marking App Plan

## Current implementation status
- Core geometry, template, validation, and package persistence layers are implemented.
- CI now runs Swift package tests, generates the Xcode project, builds the iOS simulator app, and uploads the app artifact.
- The app shell now supports project selection, template-based layout creation, and package export preview in addition to the initial planning and chalking overview screens.

## Summary
Build a native iPhone app in Swift using `ARKit` and `RealityKit` with two core modes:

1. `Planning mode` for a club representative to scan the site, register durable visual landmarks, configure one or more pitch layouts, place and rotate them on the grass, and save the result.
2. `Chalking mode` for a parent volunteer to load a saved field package, re-localize on site, mount the phone on a chalking trolley, and follow AR guidance even when landmarks leave view temporarily.

V1 should optimize for consumer iPhone hardware, offline-first usage on the field, and shareable file export/import rather than cloud sync. The map overlay stays out of core scope and is treated as a later enhancement.

## Key Changes / Implementation
### Product structure
- Ship a single iOS app with three top-level flows: `Projects`, `Planning`, and `Chalking`.
- A `Project` contains one scanned venue, one landmarking session, and many named pitch layouts such as `5A`, `5B`, and `7A`.
- Saved output is a self-contained package file, for example `*.armyrafield`, containing venue metadata, field geometry, anchors/relocalization data, and optional preview imagery so it can be shared via Messages, AirDrop, email, or a website.

### Core technical approach
- Use `ARWorldMap` and persistent AR anchors as the primary re-localization asset for a venue, backed by stored reference landmarks and a guided "scan these known objects first" recovery flow.
- Design for intermittent landmark visibility by separating:
  - `Initial localization`: acquire a confident pose from previously scanned landmarks.
  - `Operational tracking`: continue with ARKit visual-inertial odometry while monitoring drift.
  - `Recovery`: if confidence drops, pause chalk guidance and guide the user back toward previously scanned landmark-bearing edges.
- Support LiDAR opportunistically if present, but do not require it.
- Keep geometry and project data in app-defined JSON/domain models so field templates, symmetry rules, naming, editing, export/import, and future cloud sync are independent of ARKit-specific storage.

### Planning mode
- Venue scan workflow:
  - Guide the representative to walk the perimeter and capture stable landmarks such as fences, houses, and light posts.
  - Record scan quality indicators and coverage hints so the app can warn when only one side has reliable landmarks.
  - Save a venue-level confidence score and recommended re-entry points for future chalking.
- Pitch template workflow:
  - Provide built-in templates for 5-a-side, 7-a-side, 9-a-side, and 11-a-side, with editable dimensions.
  - Expose optional internal markings such as halfway line, center circle/spot, penalty areas, goal areas, and technical-area-like extras only if symmetrical.
  - Enforce symmetry rules in the editor so side-specific geometry cannot be enabled on only one end.
- Placement workflow:
  - Place a pitch by center or by a chosen corner.
  - Support locking modes: `lock center`, `lock corner`, and `lock orientation`.
  - Allow translation, rotation, and dimension tweaks after placement, with snapping and numeric fine adjustment.
  - Show overlap warnings and simple clearance checks when several pitches share one larger grass area.
- Finalization:
  - Let the representative name each pitch before save.
  - Lock the project to prevent accidental edits, while still allowing an explicit "duplicate and edit" path.

### Chalking mode
- Guided start:
  - Load a shared package and pick a pitch by name.
  - Walk the user through re-localization with visual prompts toward the best landmark side captured during planning.
- Guidance model:
  - Render the selected line set as AR overlays on grass.
  - Offer a path order optimized for chalking, for example outer perimeter first, then halfway line, then penalty and goal boxes.
  - Provide large, high-contrast trolley-friendly UI with distance-to-next-point, heading correction, and tracking confidence status.
- Drift handling:
  - Continuously classify tracking as `good`, `warning`, or `recover`.
  - In warning mode, keep showing guidance but prompt the user to slow down or look toward known landmarks.
  - In recover mode, stop line trust, preserve progress, and guide the user back to a re-localization zone before continuing.
- Practical field behavior:
  - Support starting from any corner or segment if the parent does not begin where the representative planned.
  - Allow completed segments to be marked done so interrupted chalking can resume.

### Public interfaces / data model
- Define app-domain types roughly along these lines:
  - `VenueScan`: site metadata, landmark hints, AR re-localization assets, quality score.
  - `FieldTemplate`: canonical sport dimensions and optional symmetric line groups.
  - `FieldLayout`: concrete placed pitch with transform, dimensions, enabled markings, and display name.
  - `ProjectPackage`: exportable container for one venue and many named layouts.
- Export format:
  - Versioned package manifest plus JSON geometry and AR assets.
  - Include compatibility/version checks so future app versions can migrate old packages safely.
- Import/share:
  - Support iOS share sheet, Files app import/export, and opening package files directly into the app.

## Test Plan
- Geometry tests:
  - Template generation for 5, 7, 9, and 11-a-side.
  - Symmetry enforcement for all optional internal markings.
  - Placement math for center-lock and corner-lock modes.
- Persistence tests:
  - Export/import round-trip for multi-pitch projects.
  - Version compatibility and corrupted/incomplete package handling.
- AR/workflow tests:
  - Re-localization succeeds when only one or two sides have landmarks.
  - Chalking guidance degrades safely when landmarks are not visible for long stretches.
  - Recovery flow resumes without losing already completed segments.
- Field validation:
  - On-site pilot with at least one venue containing multiple small-sided pitches on the same grass area.
  - Compare chalked line endpoints against tape-measured ground truth and define an acceptable tolerance before release.

## Assumptions and Defaults
- Native iPhone app is the target; no cross-platform requirement in v1.
- Primary sharing mechanism is a self-contained file package, not accounts or backend sync.
- V1 assumes consumer iPhones only; no external GNSS, printed fiducials, or dedicated hardware.
- The map-overlay concept is deferred until core AR planning and chalking is reliable.
- The app is optimized for amateur club use where setup guidance and drift recovery matter more than survey-grade precision.