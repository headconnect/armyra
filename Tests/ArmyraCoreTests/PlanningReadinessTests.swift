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

    func testMismatchedHandoffEdgesWarnAgainstBestCorridor() {
        let template = FieldTemplateLibrary.fiveAside
        let project = ProjectPackage(
            projectName: "Open Grounds",
            venueScan: VenueScan(
                venueName: "Main Field",
                landmarkNotes: ["West fence", "East fence", "Clubhouse goal end", "South car park"],
                recommendedRelocalizationHints: ["Start by the west fence.", "Recover by the east fence."],
                preferredStartEdge: "West fence side",
                preferredRecoveryEdge: "East fence side",
                scanCoverageScore: 0.9
            ),
            templates: [template],
            layouts: [
                template.makeLayout(
                    named: "5A",
                    transform: FieldTransform(translation: Vector2D(dx: -25, dy: 0))
                ),
                template.makeLayout(
                    named: "5B",
                    transform: FieldTransform(translation: Vector2D(dx: 25, dy: 0))
                )
            ]
        )

        let summary = PlanningReadinessAnalyzer.summarize(project: project)

        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("do not seem to line up") }))
        XCTAssertTrue(summary.handoffGuidance.contains(where: { $0.contains("Preferred venue approach is") }))
        XCTAssertTrue(summary.handoffGuidance.contains(where: { $0.contains("Primary re-entry zone: West fence side") }))
    }

    func testAlignedHandoffEdgesProduceReentryGuidanceWithoutMismatchWarning() {
        let template = FieldTemplateLibrary.fiveAside
        let project = ProjectPackage(
            projectName: "Open Grounds",
            venueScan: VenueScan(
                venueName: "Main Field",
                landmarkNotes: ["West fence", "East fence", "Clubhouse goal end", "South car park"],
                landmarks: [
                    VenueLandmark(label: "Clubhouse goal end", role: .startCandidate),
                    VenueLandmark(label: "South car park", role: .recoveryCandidate),
                    VenueLandmark(label: "West fence", role: .general),
                    VenueLandmark(label: "East fence", role: .general),
                ],
                recommendedRelocalizationHints: ["Start by the clubhouse end.", "Recover by the south car park end."],
                preferredStartEdge: "Clubhouse goal end",
                preferredRecoveryEdge: "South car park side",
                scanCoverageScore: 0.92
            ),
            templates: [template],
            layouts: [
                template.makeLayout(
                    named: "5A",
                    transform: FieldTransform(translation: Vector2D(dx: -25, dy: 0))
                ),
                template.makeLayout(
                    named: "5B",
                    transform: FieldTransform(translation: Vector2D(dx: 25, dy: 0))
                )
            ]
        )

        let summary = PlanningReadinessAnalyzer.summarize(project: project)

        XCTAssertFalse(summary.issues.contains(where: { $0.message.contains("re-entry zones") }))
        XCTAssertTrue(summary.handoffGuidance.contains(where: { $0.contains("Backup recovery zone: South car park side") }))
    }
}
