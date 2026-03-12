import XCTest
@testable import ArmyraCore

final class ChalkingGuidancePlannerTests: XCTestCase {
    func testLowCoverageVenueProducesWarning() {
        let template = FieldTemplateLibrary.fiveAside
        let layout = template.makeLayout(named: "5A", lockMode: .corner(.bottomLeft))
        let project = ProjectPackage(
            projectName: "Training Ground",
            venueScan: VenueScan(
                venueName: "North Park",
                landmarkNotes: ["Fence line"],
                recommendedRelocalizationHints: ["Start by the fence."],
                scanCoverageScore: 0.3
            ),
            templates: [template],
            layouts: [layout]
        )

        let preflight = ChalkingGuidancePlanner.makePreflight(project: project, layout: layout)

        XCTAssertEqual(preflight.readinessLevel, .low)
        XCTAssertEqual(preflight.startHint, "Start by the fence.")
        XCTAssertNotNil(preflight.warning)
    }

    func testHighCoverageVenueUsesCornerReferenceChecklist() {
        let template = FieldTemplateLibrary.sevenAside
        let layout = template.makeLayout(named: "7A", lockMode: .corner(.topRight))
        let project = ProjectPackage(
            projectName: "Community Grounds",
            venueScan: VenueScan(
                venueName: "East Field",
                landmarkNotes: ["Fence", "Clubhouse", "Floodlight mast"],
                recommendedRelocalizationHints: [
                    "Begin beside the clubhouse touchline.",
                    "Recover by facing the floodlight mast."
                ],
                scanCoverageScore: 0.82
            ),
            templates: [template],
            layouts: [layout]
        )

        let preflight = ChalkingGuidancePlanner.makePreflight(project: project, layout: layout)

        XCTAssertEqual(preflight.readinessLevel, .high)
        XCTAssertEqual(preflight.recoveryHint, "Recover by facing the floodlight mast.")
        XCTAssertTrue(preflight.checklist.contains("Begin from the top-right corner reference."))
        XCTAssertNil(preflight.warning)
    }
}
