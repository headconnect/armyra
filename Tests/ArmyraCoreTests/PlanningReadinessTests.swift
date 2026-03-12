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

    func testTightPitchSpacingProducesCaution() {
        let template = FieldTemplateLibrary.fiveAside
        let project = ProjectPackage(
            projectName: "Community Grounds",
            venueScan: VenueScan(
                venueName: "East Field",
                landmarkNotes: ["Fence", "Clubhouse", "Light mast"],
                recommendedRelocalizationHints: ["Use the clubhouse edge."],
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

        XCTAssertEqual(summary.level, .caution)
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("very close") }))
    }
}
