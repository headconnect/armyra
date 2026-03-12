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
}