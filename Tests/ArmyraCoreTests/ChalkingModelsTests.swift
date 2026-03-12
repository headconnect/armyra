import XCTest
@testable import ArmyraCore

final class ChalkingModelsTests: XCTestCase {
    func testProgressFractionUsesCompletedSegments() {
        let session = ChalkingSessionState(
            layoutID: UUID(),
            layoutName: "5A",
            completedSegments: 3,
            totalSegments: 12,
            trackingConfidence: .good,
            recommendedHint: "Keep moving.",
            guideSegments: []
        )

        XCTAssertEqual(session.progressFraction, 0.25, accuracy: 0.000_001)
    }
}
