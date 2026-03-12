import Foundation
import Testing
@testable import ArmyraCore

struct ProjectPackageStoreTests {
    @Test func packageRoundTripPreservesLayouts() throws {
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
                ),
            ]
        )

        let data = try ProjectPackageStore.encode(package)
        let decoded = try ProjectPackageStore.decode(data)

        #expect(decoded.projectName == package.projectName)
        #expect(decoded.layouts == package.layouts)
        #expect(decoded.venueScan.venueName == package.venueScan.venueName)
    }
}