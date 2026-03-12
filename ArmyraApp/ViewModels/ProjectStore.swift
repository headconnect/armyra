import SwiftUI
import ArmyraCore

@MainActor
final class ProjectStore: ObservableObject {
    @Published var projects: [ProjectPackage]
    @Published var selectedProjectID: UUID?
    @Published var selectedTemplateID: UUID?
    @Published var selectedLayoutID: UUID?
    @Published var selectedChalkingLayoutID: UUID?
    @Published var exportPreview: ExportPreview?
    @Published var exportDocument: ProjectPackageDocument?
    @Published var importErrorMessage: String?
    @Published var chalkingSession: ChalkingSessionState?
    @Published var venueScanSession: VenueScanSessionState?
    @Published var planningTrackingSnapshot: VenueTrackingSnapshot?
    @Published var chalkingTrackingSnapshot: VenueTrackingSnapshot?
    @Published var isPersistingVenueTrackingAsset = false

    private let venueTrackingService: VenueTrackingService
    private let venueScanService: VenueScanService
    private let arSessionCoordinator: ARSessionCoordinator
    private let venueTrackingAssetStore: VenueTrackingAssetStore

    struct ExportPreview: Identifiable {
        let id = UUID()
        let fileName: String
        let payload: String
    }

    init(
        projects: [ProjectPackage],
        venueTrackingService: VenueTrackingService = MockVenueTrackingService(),
        venueScanService: VenueScanService = MockVenueScanService(),
        arSessionCoordinator: ARSessionCoordinator = DefaultARSessionCoordinatorFactory.make(),
        venueTrackingAssetStore: VenueTrackingAssetStore = DefaultVenueTrackingAssetStoreFactory.make()
    ) {
        self.projects = projects
        self.venueTrackingService = venueTrackingService
        self.venueScanService = venueScanService
        self.arSessionCoordinator = arSessionCoordinator
        self.venueTrackingAssetStore = venueTrackingAssetStore
        self.selectedProjectID = projects.first?.id
        self.selectedTemplateID = projects.first?.templates.first?.id
        self.selectedLayoutID = projects.first?.layouts.first?.id
        self.selectedChalkingLayoutID = projects.first?.layouts.first?.id
        if let venueScan = projects.first?.venueScan {
            self.planningTrackingSnapshot = arSessionCoordinator.planningSnapshot(for: venueScan)
        }
    }

    var selectedProject: ProjectPackage? {
        projects.first(where: { $0.id == selectedProjectID }) ?? projects.first
    }

    var selectedTemplate: FieldTemplate? {
        guard let project = selectedProject else { return nil }
        return project.templates.first(where: { $0.id == selectedTemplateID }) ?? project.templates.first
    }

    var selectedLayout: FieldLayout? {
        guard let project = selectedProject else { return nil }
        return project.layouts.first(where: { $0.id == selectedLayoutID }) ?? project.layouts.first
    }

    var selectedChalkingLayout: FieldLayout? {
        guard let project = selectedProject else { return nil }
        return project.layouts.first(where: { $0.id == selectedChalkingLayoutID }) ?? project.layouts.first
    }

    func selectProject(_ projectID: UUID) {
        selectedProjectID = projectID
        selectedTemplateID = selectedProject?.templates.first?.id
        selectedLayoutID = selectedProject?.layouts.first?.id
        selectedChalkingLayoutID = selectedProject?.layouts.first?.id
        chalkingSession = nil
        venueScanSession = nil
        chalkingTrackingSnapshot = nil
        planningTrackingSnapshot = selectedProject.map { arSessionCoordinator.planningSnapshot(for: $0.venueScan) }
        arSessionCoordinator.stopSession()
    }

    func selectLayout(_ layoutID: UUID) {
        selectedLayoutID = layoutID
    }

    func addLayoutFromSelectedTemplate() {
        guard let projectIndex = selectedProjectIndex, let template = selectedTemplate else { return }

        let name = nextLayoutName(for: template.pitchSize, layouts: projects[projectIndex].layouts)
        let offset = Double(projects[projectIndex].layouts.count) * 8
        let layout = template.makeLayout(
            named: name,
            transform: FieldTransform(translation: Vector2D(dx: offset, dy: 0)),
            lockMode: .center
        )

        projects[projectIndex].layouts.append(layout)
        selectedLayoutID = layout.id
    }

    func showExportPreview() {
        guard let project = selectedProject, let payload = try? ProjectPackageStore.encodeString(project) else {
            return
        }

        exportPreview = ExportPreview(
            fileName: ProjectPackageStore.suggestedFileName(for: project),
            payload: payload
        )
    }

    func prepareExportDocument() {
        guard let project = selectedProject else { return }
        exportDocument = ProjectPackageDocument(project: project)
    }

    func dismissExportPreview() {
        exportPreview = nil
    }

    func dismissImportError() {
        importErrorMessage = nil
    }

    func markingsDescription(for layout: FieldLayout) -> String {
        let markings = layout.enabledMarkings
            .map(\.rawValue)
            .sorted()
            .joined(separator: ", ")

        return markings.isEmpty ? "Outer perimeter only" : markings
    }

    func updateSelectedLayoutName(_ name: String) {
        updateSelectedLayout { layout in
            layout.name = name
        }
    }

    func updateSelectedLayoutLength(_ length: Double) {
        updateSelectedLayout { layout in
            layout.dimensions.lengthMeters = max(1, length)
        }
    }

    func updateSelectedLayoutWidth(_ width: Double) {
        updateSelectedLayout { layout in
            layout.dimensions.widthMeters = max(1, width)
        }
    }

    func updateSelectedLayoutRotationDegrees(_ degrees: Double) {
        updateSelectedLayout { layout in
            layout.transform.rotationRadians = degrees * .pi / 180
        }
    }

    func updateSelectedLayoutOffsetX(_ offsetX: Double) {
        updateSelectedLayout { layout in
            layout.transform.translation.dx = offsetX
        }
    }

    func updateSelectedLayoutOffsetY(_ offsetY: Double) {
        updateSelectedLayout { layout in
            layout.transform.translation.dy = offsetY
        }
    }

    func updateSelectedLayoutLockMode(_ lockMode: PlacementLockMode) {
        updateSelectedLayout { layout in
            layout.lockMode = lockMode
        }
    }

    func setSelectedLayoutMarking(_ marking: LineMarking, isEnabled: Bool) {
        guard let layout = selectedLayout,
              let template = selectedProject?.templates.first(where: { $0.id == layout.templateID }),
              template.supportedMarkings.contains(marking) else {
            return
        }

        updateSelectedLayout { layout in
            if isEnabled {
                layout.enabledMarkings.insert(marking)
            } else {
                layout.enabledMarkings.remove(marking)
            }
        }
    }

    func isSelectedLayoutMarkingEnabled(_ marking: LineMarking) -> Bool {
        selectedLayout?.enabledMarkings.contains(marking) ?? false
    }

    func supportedMarkingsForSelectedLayout() -> [LineMarking] {
        guard let layout = selectedLayout,
              let template = selectedProject?.templates.first(where: { $0.id == layout.templateID }) else {
            return []
        }

        return template.supportedMarkings.sorted { $0.rawValue < $1.rawValue }
    }

    func duplicateSelectedProject() {
        guard let project = selectedProject else { return }

        let duplicated = ProjectPackage(
            projectName: "\(project.projectName) Copy",
            venueScan: VenueScan(
                venueName: project.venueScan.venueName,
                landmarkNotes: project.venueScan.landmarkNotes,
                recommendedRelocalizationHints: project.venueScan.recommendedRelocalizationHints,
                scanCoverageScore: project.venueScan.scanCoverageScore,
                worldMapData: project.venueScan.worldMapData
            ),
            templates: project.templates,
            layouts: project.layouts.map { layout in
                FieldLayout(
                    name: layout.name,
                    templateID: layout.templateID,
                    dimensions: layout.dimensions,
                    enabledMarkings: layout.enabledMarkings,
                    transform: layout.transform,
                    lockMode: layout.lockMode
                )
            },
            lockedAt: nil
        )

        projects.append(duplicated)
        selectProject(duplicated.id)
    }

    func importProject(from document: ProjectPackageDocument) {
        projects.append(document.project)
        selectProject(document.project.id)
    }

    func handleImportFailure(_ error: Error) {
        importErrorMessage = error.localizedDescription
    }

    func startVenueScanSession() {
        guard let project = selectedProject else { return }
        arSessionCoordinator.startPlanningSession(for: project.venueScan)
        venueScanSession = venueScanService.startSession(for: project.venueScan)
        planningTrackingSnapshot = arSessionCoordinator.planningSnapshot(for: project.venueScan)
    }

    func captureVenueLandmark(_ landmark: String) {
        guard let venueScanSession, let project = selectedProject else { return }
        let updatedSession = venueScanService.captureLandmark(landmark, session: venueScanSession)
        self.venueScanSession = updatedSession
        planningTrackingSnapshot = arSessionCoordinator.planningSnapshot(
            for: venueScanDraft(session: updatedSession, original: project.venueScan)
        )
    }

    func advanceVenueCoverage() {
        guard let venueScanSession, let project = selectedProject else { return }
        let updatedSession = venueScanService.advanceCoverage(session: venueScanSession)
        self.venueScanSession = updatedSession
        planningTrackingSnapshot = arSessionCoordinator.planningSnapshot(
            for: venueScanDraft(session: updatedSession, original: project.venueScan)
        )
    }

    func finalizeVenueScanSession() {
        guard let projectIndex = selectedProjectIndex,
              let venueScanSession else { return }

        let finalizedScan = venueScanService.finalize(
            session: venueScanSession,
            original: projects[projectIndex].venueScan
        )
        projects[projectIndex].venueScan = finalizedScan
        planningTrackingSnapshot = arSessionCoordinator.planningSnapshot(for: finalizedScan)
        self.venueScanSession = nil
        isPersistingVenueTrackingAsset = true

        Task { @MainActor in
            let (asset, payload) = await arSessionCoordinator.capturePlanningAsset(for: finalizedScan)
            venueTrackingAssetStore.save(asset, payload: payload)
            isPersistingVenueTrackingAsset = false
            arSessionCoordinator.stopSession()
        }
    }

    func discardVenueScanSession() {
        venueScanSession = nil
        planningTrackingSnapshot = selectedProject.map { arSessionCoordinator.planningSnapshot(for: $0.venueScan) }
        arSessionCoordinator.stopSession()
    }

    func selectChalkingLayout(_ layoutID: UUID) {
        selectedChalkingLayoutID = layoutID
    }

    func startChalkingSession() {
        guard let project = selectedProject, let layout = selectedChalkingLayout else { return }
        let asset = latestVenueTrackingAsset()
        let payload = asset.flatMap { venueTrackingAssetStore.payload(for: $0) }
        arSessionCoordinator.startChalkingSession(for: project.venueScan, assetData: payload)
        chalkingSession = venueTrackingService.startSession(project: project, layout: layout)
        chalkingTrackingSnapshot = arSessionCoordinator.chalkingSnapshot(
            project: project,
            layout: layout,
            confidence: chalkingSession?.trackingConfidence ?? .good
        )
    }

    func advanceChalkingSession() {
        guard let project = selectedProject,
              let layout = selectedChalkingLayout,
              let chalkingSession else { return }

        let updatedSession = venueTrackingService.advance(chalkingSession, project: project, layout: layout)
        self.chalkingSession = updatedSession
        chalkingTrackingSnapshot = arSessionCoordinator.chalkingSnapshot(
            project: project,
            layout: layout,
            confidence: updatedSession.trackingConfidence
        )
    }

    func cycleTrackingConfidence() {
        guard let project = selectedProject,
              let layout = selectedChalkingLayout,
              let chalkingSession else { return }

        let updatedSession = venueTrackingService.cycleConfidence(chalkingSession, project: project, layout: layout)
        self.chalkingSession = updatedSession
        chalkingTrackingSnapshot = arSessionCoordinator.chalkingSnapshot(
            project: project,
            layout: layout,
            confidence: updatedSession.trackingConfidence
        )
    }

    func endChalkingSession() {
        chalkingSession = nil
        chalkingTrackingSnapshot = nil
        arSessionCoordinator.stopSession()
    }

    func selectedLayoutRotationDegrees() -> Double {
        guard let selectedLayout else { return 0 }
        return selectedLayout.transform.rotationRadians * 180 / .pi
    }

    func boundingBox(for layout: FieldLayout) -> FieldBoundingBox {
        FieldLayoutAnalysis.boundingBox(for: layout)
    }

    func planningExtent() -> FieldBoundingBox? {
        guard let project = selectedProject else { return nil }
        let boxes = project.layouts.map { FieldLayoutAnalysis.boundingBox(for: $0) }
        return FieldBoundingBox.union(boxes)
    }

    func overlappingLayoutNames() -> [String] {
        guard let project = selectedProject else { return [] }
        let nameByID = Dictionary(uniqueKeysWithValues: project.layouts.map { ($0.id, $0.name) })

        return FieldLayoutAnalysis.overlaps(in: project.layouts).map { overlap in
            let first = nameByID[overlap.firstLayoutID] ?? "Unknown"
            let second = nameByID[overlap.secondLayoutID] ?? "Unknown"
            return "\(first) overlaps \(second)"
        }
    }

    func venueCoverageDescription() -> String {
        let score = venueScanSession?.readinessScore ?? selectedProject?.venueScan.scanCoverageScore ?? 0
        let percentage = Int((score * 100).rounded())
        return "\(percentage)% ready"
    }

    func planningRelocalizationLabel() -> String {
        relocalizationLabel(for: planningTrackingSnapshot?.relocalizationState ?? .unavailable)
    }

    func chalkingRelocalizationLabel() -> String {
        relocalizationLabel(for: chalkingTrackingSnapshot?.relocalizationState ?? .unavailable)
    }

    func latestVenueTrackingAsset() -> VenueTrackingAssetRecord? {
        guard let venueScanID = selectedProject?.venueScan.id else { return nil }
        return venueTrackingAssetStore.latestAsset(for: venueScanID)
    }

    func availableMockLandmarks() -> [String] {
        [
            "Fence line",
            "Clubhouse",
            "Floodlight mast",
            "House roof",
            "Car park entrance",
            "Bench shelter"
        ]
    }

    private var selectedProjectIndex: Int? {
        guard let selectedProjectID else { return projects.isEmpty ? nil : 0 }
        return projects.firstIndex(where: { $0.id == selectedProjectID }) ?? (projects.isEmpty ? nil : 0)
    }

    private func updateSelectedLayout(_ update: (inout FieldLayout) -> Void) {
        guard let projectIndex = selectedProjectIndex else { return }
        guard let layoutID = selectedLayoutID ?? projects[projectIndex].layouts.first?.id else { return }
        guard let layoutIndex = projects[projectIndex].layouts.firstIndex(where: { $0.id == layoutID }) else { return }

        update(&projects[projectIndex].layouts[layoutIndex])
    }

    private func venueScanDraft(session: VenueScanSessionState, original: VenueScan) -> VenueScan {
        VenueScan(
            id: original.id,
            venueName: original.venueName,
            landmarkNotes: session.capturedLandmarks,
            recommendedRelocalizationHints: [session.recommendedHint],
            scanCoverageScore: session.readinessScore,
            worldMapData: original.worldMapData
        )
    }

    private func relocalizationLabel(for state: RelocalizationState) -> String {
        switch state {
        case .unavailable:
            return "No relocalization asset"
        case .scanning:
            return "Scanning for relocalization"
        case .localized:
            return "Relocalized"
        case .limited:
            return "Limited relocalization"
        }
    }

    private func nextLayoutName(for pitchSize: PitchSize, layouts: [FieldLayout]) -> String {
        let prefix = pitchSize.playerCountLabel
        let matching = layouts.filter { $0.name.hasPrefix(prefix) }
        let suffixUnicode = 65 + matching.count
        let suffix = UnicodeScalar(suffixUnicode).map(String.init) ?? "Z"
        return "\(prefix)\(suffix)"
    }

    static var preview: ProjectStore {
        let fiveTemplate = FieldTemplateLibrary.fiveAside
        let sevenTemplate = FieldTemplateLibrary.sevenAside

        let project = ProjectPackage(
            projectName: "Community Grounds",
            venueScan: VenueScan(
                venueName: "North Park",
                landmarkNotes: [
                    "Fence line on the west touchline",
                    "Clubhouse roof behind the south goal",
                    "Floodlight mast near the corner flag"
                ],
                recommendedRelocalizationHints: [
                    "Start next to the west fence for the strongest relocalization",
                    "If tracking drifts, turn the trolley toward the clubhouse and rescan"
                ],
                scanCoverageScore: 0.78
            ),
            templates: [fiveTemplate, sevenTemplate],
            layouts: [
                fiveTemplate.makeLayout(
                    named: "5A",
                    transform: FieldTransform(
                        translation: Vector2D(dx: -25, dy: 0),
                        rotationRadians: 0
                    ),
                    lockMode: .corner(.bottomLeft)
                ),
                fiveTemplate.makeLayout(
                    named: "5B",
                    enabledMarkings: [.halfwayLine, .centerSpot, .penaltyArea],
                    transform: FieldTransform(
                        translation: Vector2D(dx: 25, dy: 0),
                        rotationRadians: 0
                    ),
                    lockMode: .corner(.bottomRight)
                ),
                sevenTemplate.makeLayout(
                    named: "7A",
                    transform: FieldTransform(
                        translation: Vector2D(dx: 0, dy: 35),
                        rotationRadians: .pi / 24
                    ),
                    lockMode: .center
                )
            ],
            lockedAt: Date()
        )

        return ProjectStore(projects: [project])
    }
}
