import SwiftUI
import ArmyraCore

@MainActor
final class ProjectStore: ObservableObject {
    @Published var projects: [ProjectPackage]
    @Published var selectedProjectID: UUID?
    @Published var selectedTemplateID: UUID?
    @Published var exportPreview: ExportPreview?

    struct ExportPreview: Identifiable {
        let id = UUID()
        let fileName: String
        let payload: String
    }

    init(projects: [ProjectPackage]) {
        self.projects = projects
        self.selectedProjectID = projects.first?.id
        self.selectedTemplateID = projects.first?.templates.first?.id
    }

    var selectedProject: ProjectPackage? {
        projects.first(where: { $0.id == selectedProjectID }) ?? projects.first
    }

    var selectedTemplate: FieldTemplate? {
        guard let project = selectedProject else { return nil }
        return project.templates.first(where: { $0.id == selectedTemplateID }) ?? project.templates.first
    }

    func selectProject(_ projectID: UUID) {
        selectedProjectID = projectID
        selectedTemplateID = selectedProject?.templates.first?.id
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

    func dismissExportPreview() {
        exportPreview = nil
    }

    func markingsDescription(for layout: FieldLayout) -> String {
        let markings = layout.enabledMarkings
            .map(\.rawValue)
            .sorted()
            .joined(separator: ", ")

        return markings.isEmpty ? "Outer perimeter only" : markings
    }

    private var selectedProjectIndex: Int? {
        guard let selectedProjectID else { return projects.isEmpty ? nil : 0 }
        return projects.firstIndex(where: { $0.id == selectedProjectID }) ?? (projects.isEmpty ? nil : 0)
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