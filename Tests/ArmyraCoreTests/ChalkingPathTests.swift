import XCTest
@testable import ArmyraCore

final class ChalkingPathTests: XCTestCase {
    func testFieldGeometryBuilderCreatesNamedGuideSegments() {
        let template = FieldTemplateLibrary.fiveAside
        let layout = template.makeLayout(
            named: "5A",
            enabledMarkings: [.halfwayLine, .penaltyArea]
        )

        let geometry = FieldGeometryBuilder.build(for: layout)

        XCTAssertEqual(geometry.guidePath.count, geometry.guideSegments.count)
        XCTAssertEqual(geometry.guideSegments.first?.label, "Top touchline")
        XCTAssertTrue(geometry.guideSegments.contains(where: { $0.label == "Halfway line" }))
        XCTAssertTrue(geometry.guideSegments.contains(where: { $0.label.contains("Penalty area") }))
    }

    func testChalkingSessionExposesCurrentAndUpcomingSegments() {
        let segments = [
            GuideSegment(kind: .boundary, label: "Top touchline", segment: LineSegment(start: Point2D(x: 0, y: 0), end: Point2D(x: 1, y: 0))),
            GuideSegment(kind: .boundary, label: "Right goal line", segment: LineSegment(start: Point2D(x: 1, y: 0), end: Point2D(x: 1, y: 1))),
            GuideSegment(kind: .interior, label: "Halfway line", segment: LineSegment(start: Point2D(x: 0.5, y: 0), end: Point2D(x: 0.5, y: 1))),
        ]

        let session = ChalkingSessionState(
            layoutID: UUID(),
            layoutName: "5A",
            completedSegments: 1,
            totalSegments: 3,
            trackingConfidence: .good,
            recommendedHint: "Continue",
            guideSegments: segments
        )

        XCTAssertEqual(session.currentSegment?.label, "Right goal line")
        XCTAssertEqual(session.upcomingSegments.map(\.label), ["Halfway line"])
    }
}
