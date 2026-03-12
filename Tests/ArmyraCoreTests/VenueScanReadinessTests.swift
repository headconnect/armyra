import XCTest
@testable import ArmyraCore

final class VenueScanReadinessTests: XCTestCase {
    func testOneSidedThinScanNeedsWork() {
        let session = VenueScanSessionState(
            venueName: "North Park",
            capturedLandmarks: ["Fence line", "Clubhouse"],
            coveredSides: 1,
            readinessScore: 0.42,
            phase: .scanning,
            recommendedHint: "Capture another edge."
        )

        let summary = VenueScanReadinessAnalyzer.summarize(session: session)

        XCTAssertEqual(summary.level, .needsWork)
        XCTAssertFalse(summary.canLockForHandoff)
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("Only one edge") }))
    }

    func testBroadVenueScanCanLockForHandoff() {
        let venueScan = VenueScan(
            venueName: "Community Grounds",
            landmarkNotes: ["West fence", "Clubhouse", "Floodlight mast", "House roof", "Car park gate"],
            recommendedRelocalizationHints: [
                "Start from the west fence side.",
                "If tracking softens, return toward the clubhouse side."
            ],
            preferredStartEdge: "West fence side",
            preferredRecoveryEdge: "Clubhouse side",
            scanCoverageScore: 0.9
        )

        let summary = VenueScanReadinessAnalyzer.summarize(venueScan: venueScan)

        XCTAssertEqual(summary.level, .ready)
        XCTAssertTrue(summary.canLockForHandoff)
        XCTAssertTrue(summary.issues.isEmpty)
    }
}
