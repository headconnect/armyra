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
            landmarkNotes: ["West fence", "South clubhouse", "North floodlight mast", "East house roof", "South car park gate"],
            landmarks: [
                VenueLandmark(label: "West fence", role: .startCandidate),
                VenueLandmark(label: "South clubhouse", role: .recoveryCandidate),
                VenueLandmark(label: "North floodlight mast", role: .general),
                VenueLandmark(label: "East house roof", role: .general),
                VenueLandmark(label: "South car park gate", role: .general),
            ],
            recommendedRelocalizationHints: [
                "Start from the west fence side.",
                "If tracking softens, return toward the clubhouse side."
            ],
            preferredStartEdge: "West fence side",
            preferredRecoveryEdge: "South clubhouse side",
            scanCoverageScore: 0.9
        )

        let summary = VenueScanReadinessAnalyzer.summarize(venueScan: venueScan)

        XCTAssertEqual(summary.level, .ready)
        XCTAssertTrue(summary.canLockForHandoff)
        XCTAssertTrue(summary.issues.isEmpty)
        XCTAssertEqual(summary.startCandidateCount, 1)
        XCTAssertEqual(summary.recoveryCandidateCount, 1)
        XCTAssertEqual(summary.inferredLandmarkZoneCount, 4)
        XCTAssertGreaterThanOrEqual(summary.inferredLandmarkKindCount, 4)
    }

    func testSameStartAndRecoveryEdgeProducesCaution() {
        let session = VenueScanSessionState(
            venueName: "South Ground",
            capturedLandmarks: ["West fence", "Clubhouse", "Floodlight mast", "House roof"],
            coveredSides: 3,
            preferredStartEdge: "West fence",
            preferredRecoveryEdge: "West fence",
            readinessScore: 0.86,
            phase: .ready,
            recommendedHint: "Use the west fence edge."
        )

        let summary = VenueScanReadinessAnalyzer.summarize(session: session)

        XCTAssertEqual(summary.level, .caution)
        XCTAssertFalse(summary.canLockForHandoff)
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("same") }))
    }

    func testMissingRoleTagsKeepOtherwiseStrongScanInCaution() {
        let session = VenueScanSessionState(
            venueName: "North Park",
            capturedLandmarks: ["West fence", "Clubhouse", "Floodlight mast", "House roof", "Car park gate"],
            landmarks: [
                VenueLandmark(label: "West fence", role: .general),
                VenueLandmark(label: "Clubhouse", role: .general),
                VenueLandmark(label: "Floodlight mast", role: .general),
                VenueLandmark(label: "House roof", role: .general),
                VenueLandmark(label: "Car park gate", role: .general),
            ],
            coveredSides: 3,
            preferredStartEdge: "West fence",
            preferredRecoveryEdge: "Clubhouse",
            readinessScore: 0.88,
            phase: .ready,
            recommendedHint: "Use the west fence edge."
        )

        let summary = VenueScanReadinessAnalyzer.summarize(session: session)

        XCTAssertEqual(summary.level, .caution)
        XCTAssertFalse(summary.canLockForHandoff)
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("start-side candidate") }))
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("recovery-side candidate") }))
    }

    func testThinScanWithoutRecoveryRoleNeedsWork() {
        let session = VenueScanSessionState(
            venueName: "South Ground",
            capturedLandmarks: ["West fence", "Clubhouse", "Floodlight mast"],
            landmarks: [
                VenueLandmark(label: "West fence", role: .startCandidate),
                VenueLandmark(label: "Clubhouse", role: .general),
                VenueLandmark(label: "Floodlight mast", role: .general),
            ],
            coveredSides: 2,
            preferredStartEdge: "West fence",
            preferredRecoveryEdge: "Clubhouse",
            readinessScore: 0.6,
            phase: .scanning,
            recommendedHint: "Capture another edge."
        )

        let summary = VenueScanReadinessAnalyzer.summarize(session: session)

        XCTAssertEqual(summary.level, .needsWork)
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("recovery-side candidate") }))
    }

    func testChosenEdgesMustMatchTaggedRoles() {
        let session = VenueScanSessionState(
            venueName: "East Ground",
            capturedLandmarks: ["West fence", "Clubhouse", "Floodlight mast", "House roof", "Car park gate"],
            landmarks: [
                VenueLandmark(label: "West fence", role: .general),
                VenueLandmark(label: "Clubhouse", role: .startCandidate),
                VenueLandmark(label: "Floodlight mast", role: .recoveryCandidate),
                VenueLandmark(label: "House roof", role: .general),
                VenueLandmark(label: "Car park gate", role: .general),
            ],
            coveredSides: 3,
            preferredStartEdge: "West fence",
            preferredRecoveryEdge: "House roof",
            readinessScore: 0.9,
            phase: .ready,
            recommendedHint: "Use the clubhouse side."
        )

        let summary = VenueScanReadinessAnalyzer.summarize(session: session)

        XCTAssertEqual(summary.level, .caution)
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("chosen start edge") }))
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("chosen recovery edge") }))
    }

    func testClusteredLandmarksWarnAboutPoorSpread() {
        let session = VenueScanSessionState(
            venueName: "West Bank",
            capturedLandmarks: ["West fence", "West bench shelter", "West floodlight mast", "West car park gate"],
            landmarks: [
                VenueLandmark(label: "West fence", role: .startCandidate),
                VenueLandmark(label: "West bench shelter", role: .recoveryCandidate),
                VenueLandmark(label: "West floodlight mast", role: .general),
                VenueLandmark(label: "West car park gate", role: .general),
            ],
            coveredSides: 3,
            preferredStartEdge: "West fence",
            preferredRecoveryEdge: "West bench shelter",
            readinessScore: 0.88,
            phase: .ready,
            recommendedHint: "Use the west side."
        )

        let summary = VenueScanReadinessAnalyzer.summarize(session: session)

        XCTAssertEqual(summary.level, .caution)
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("clustered around one part") }))
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("same part of the venue") }))
        XCTAssertTrue(summary.issues.contains(where: { $0.message.contains("same kind of object") }))
        XCTAssertEqual(summary.inferredLandmarkZoneCount, 1)
        XCTAssertTrue(summary.suggestedCaptureZones.contains("north"))
        XCTAssertTrue(summary.suggestedCaptureZones.contains("east"))
        XCTAssertTrue(summary.suggestedCaptureKinds.contains("building"))
        XCTAssertTrue(summary.suggestedCaptureKinds.contains("light post"))
    }
}
