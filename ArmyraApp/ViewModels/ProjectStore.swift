import SwiftUI
import ArmyraCore

@MainActor
final class ProjectStore: ObservableObject {
    @Published var projects: [ProjectPackage]
    @Published var selectedProjectID: UUID?

    init(projects: [ProjectPackage]) {
        self.projects = projects
        self.selectedProjectID = projects.first?.id
    }

    var selectedProject: ProjectPackage? {
        projects.first(where: { $0.id == selectedProjectID }) ?? projects.first
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
                FieldLayout(
                    name: "5A",
                    templateID: fiveTemplate.id,
                    dimensions: fiveTemplate.dimensions,
                    enabledMarkings: fiveTemplate.defaultMarkings,
                    transform: FieldTransform(
                        translation: Vector2D(dx: -25, dy: 0),
                        rotationRadians: 0
                    ),
                    lockMode: .corner(.bottomLeft)
                ),
                FieldLayout(
                    name: "5B",
                    templateID: fiveTemplate.id,
                    dimensions: fiveTemplate.dimensions,
                    enabledMarkings: [.halfwayLine, .centerSpot, .penaltyArea],
                    transform: FieldTransform(
                        translation: Vector2D(dx: 25, dy: 0),
                        rotationRadians: 0
                    ),
                    lockMode: .corner(.bottomRight)
                ),
                FieldLayout(
                    name: "7A",
                    templateID: sevenTemplate.id,
                    dimensions: sevenTemplate.dimensions,
                    enabledMarkings: sevenTemplate.defaultMarkings,
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