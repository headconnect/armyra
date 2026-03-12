import XCTest
@testable import ArmyraCore

final class ARBoundaryModelsTests: XCTestCase {
    func testVenueTrackingSnapshotStoresReadinessAndHint() {
        let venueScanID = UUID()
        let snapshot = VenueTrackingSnapshot(
            venueScanID: venueScanID,
            relocalizationState: .localized,
            readinessScore: 0.84,
            activeHint: "Start by the clubhouse edge."
        )

        XCTAssertEqual(snapshot.venueScanID, venueScanID)
        XCTAssertEqual(snapshot.relocalizationState, .localized)
        XCTAssertEqual(snapshot.readinessScore, 0.84, accuracy: 0.001)
        XCTAssertEqual(snapshot.activeHint, "Start by the clubhouse edge.")
    }

    func testVenueTrackingAssetRecordIsSeparateFromPackageShape() {
        let venueScanID = UUID()
        let asset = VenueTrackingAssetRecord(
            venueScanID: venueScanID,
            localStorageKey: "mock-asset-123",
            readinessScore: 0.72
        )

        XCTAssertEqual(asset.venueScanID, venueScanID)
        XCTAssertEqual(asset.localStorageKey, "mock-asset-123")
        XCTAssertEqual(asset.readinessScore, 0.72, accuracy: 0.001)
    }
}
