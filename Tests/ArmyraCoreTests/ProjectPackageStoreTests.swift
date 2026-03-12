import Foundation
import XCTest
@testable import ArmyraCore

final class ProjectPackageStoreTests: XCTestCase {
    func testPackageRoundTripPreservesLayouts() throws {
        let template = FieldTemplateLibrary.nineAside
        let package = ProjectPackage(
            projectName: "Training Ground",
            venueScan: VenueScan(
                venueName: "North Field",
                landmarkNotes: ["Fence on west side", "Lightpost at southeast corner"],
                landmarks: [
                    VenueLandmark(label: "Fence on west side", role: .startCandidate),
                    VenueLandmark(label: "Lightpost at southeast corner", role: .recoveryCandidate),
                ],
                recommendedRelocalizationHints: ["Start near the clubhouse fence"],
                preferredStartEdge: "West fence side",
                preferredRecoveryEdge: "Lightpost corner",
                scanCoverageScore: 0.72
            ),
            templates: [template],
            layouts: [
                FieldLayout(
                    name: "9A",
                    templateID: template.id,
                    dimensions: template.dimensions,
                    enabledMarkings: template.defaultMarkings
                )
            ]
        )

        let data = try ProjectPackageStore.encode(package)
        let decoded = try ProjectPackageStore.decode(data)

        XCTAssertEqual(decoded.projectName, package.projectName)
        XCTAssertEqual(decoded.layouts, package.layouts)
        XCTAssertEqual(decoded.venueScan.venueName, package.venueScan.venueName)
        XCTAssertEqual(decoded.venueScan.landmarks, package.venueScan.landmarks)
        XCTAssertEqual(decoded.venueScan.preferredStartEdge, package.venueScan.preferredStartEdge)
        XCTAssertEqual(decoded.venueScan.preferredRecoveryEdge, package.venueScan.preferredRecoveryEdge)
    }

    func testSuggestedFileNameSanitizesProjectName() {
        let package = ProjectPackage(
            projectName: "North Park 5A / 5B",
            venueScan: VenueScan(
                venueName: "North Field",
                landmarkNotes: [],
                recommendedRelocalizationHints: [],
                scanCoverageScore: 1
            ),
            templates: [],
            layouts: []
        )

        XCTAssertEqual(ProjectPackageStore.suggestedFileName(for: package), "north-park-5a--5b.armyrafield")
    }
}
