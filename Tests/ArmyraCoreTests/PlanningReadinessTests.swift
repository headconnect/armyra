import XCTest
@testable import ArmyraCore

final class PlanningReadinessTests: XCTestCase {
    func testWeakVenueScanIsNotParentSafe() {
        let template = FieldTemplateLibrary.fiveAside
        let project = ProjectPackage(
            projectName: "Training Ground",
            venueScan: VenueScan(
                venueName: "North Park",
                landmarkNotes: ["Fence line"],
                recommendedRelocalizationHints: ["Start by the fence."],
                scanCoverageScore: 0.3
            ),
            templates: [template],
            layouts: [template.makeLayout(named: "5A")]
        )

        let summary = PlanningReadinessAnalyzer.summarize(project: project)

        XCTAssertEqual(summary.level, .needsWork)
        XCTAssertFalse(summary.parentSafe)
    }

    func testTightPitchSpacingCanEscalateWhenLaneIsTooNarrow() {
        let template = FieldTemplateLibrary.fiveAside
        let project = ProjectPackage(
            projectName: "Community Grounds",
            venueScan: VenueScan(
                venueName: "East Field",
                landmarkNotes: ["Fence", "Clubhouse", "Light mast"],
                recommendedRelocalizationHints: ["Use the clubhouse edge."],
                preferredStartEdge: "Clubhouse edge",
                preferredRecoveryEdge: "Fence edge",
                scanCoverageScore: 0.82
            ),
            templates: [template],
            layouts: [
                template.makeLayout(
                    named: "5A",
                    transform: FieldTransform(translation: Vector2D(dx: 0, dy: 0))
                ),
                template.makeLayout(
                    named: "5B",
                    transform: FieldTransform(translation: Vector2D(dx: 42, dy: 0))
                )
            ]
        )

        let summary = PlanningReadinessAnalyzer.summarize(project: project)

        XCTAssertEqual(summary.level, .needsWork)
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("very close") }))
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("practical chalking lane") }))
    }

    func testNarrowChalkingLaneCanEscalateToNeedsWork() {
        let template = FieldTemplateLibrary.fiveAside
        let project = ProjectPackage(
            projectName: "Festival Setup",
            venueScan: VenueScan(
                venueName: "West Field",
                landmarkNotes: ["Fence", "Clubhouse", "Light mast", "House roof", "Bench shelter"],
                recommendedRelocalizationHints: ["Use the clubhouse edge.", "Recover toward the fence."],
                preferredStartEdge: "Clubhouse edge",
                preferredRecoveryEdge: "Fence edge",
                scanCoverageScore: 0.9
            ),
            templates: [template],
            layouts: [
                template.makeLayout(
                    named: "5A",
                    transform: FieldTransform(translation: Vector2D(dx: 0, dy: 0))
                ),
                template.makeLayout(
                    named: "5B",
                    transform: FieldTransform(translation: Vector2D(dx: 41, dy: 0))
                )
            ]
        )

        let summary = PlanningReadinessAnalyzer.summarize(project: project)

        XCTAssertEqual(summary.level, .needsWork)
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("practical chalking lane") }))
    }
}
