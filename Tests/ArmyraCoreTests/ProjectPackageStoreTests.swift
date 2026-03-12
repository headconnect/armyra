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
                recommendedRelocalizationHints: ["Start near the clubhouse fence"],
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