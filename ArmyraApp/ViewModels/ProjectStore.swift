import SwiftUI
import ArmyraCore

@MainActor
final class ProjectStore: ObservableObject {
    @Published var projects: [ProjectPackage]
    @Published var selectedProjectID: UUID?
    @Published var selectedTemplateID: UUID?
    @Published var selectedLayoutID: UUID?
    @Published var exportPreview: ExportPreview?
    @Published var exportDocument: ProjectPackageDocument?
    @Published var importErrorMessage: String?

    struct ExportPreview: Identifiable {
        let id = UUID()
        let fileName: String
        let payload: String
    }

    init(projects: [ProjectPackage]) {
        self.projects = projects
        self.selectedProjectID = projects.first?.id
        self.selectedTemplateID = projects.first?.templates.first?.id
        self.selectedLayoutID = projects.first?.layouts.first?.id
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

    func selectProject(_ projectID: UUID) {
        selectedProjectID = projectID
        selectedTemplateID = selectedProject?.templates.first?.id
        selectedLayoutID = selectedProject?.layouts.first?.id
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

    func selectedLayoutRotationDegrees() -> Double {
        guard let selectedLayout else { return 0 }
        return selectedLayout.transform.rotationRadians * 180 / .pi
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
