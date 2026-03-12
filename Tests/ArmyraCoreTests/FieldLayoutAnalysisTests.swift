import XCTest
@testable import ArmyraCore

final class FieldLayoutAnalysisTests: XCTestCase {
    func testBoundingBoxReflectsRotationAndTranslation() {
        let template = FieldTemplateLibrary.fiveAside
        let layout = template.makeLayout(
            named: "5A",
            transform: FieldTransform(
                translation: Vector2D(dx: 10, dy: -5),
                rotationRadians: .pi / 2
            )
        )

        let box = FieldLayoutAnalysis.boundingBox(for: layout)

        XCTAssertEqual(box.minX, -5, accuracy: 0.000_001)
        XCTAssertEqual(box.maxX, 25, accuracy: 0.000_001)
        XCTAssertEqual(box.minY, -25, accuracy: 0.000_001)
        XCTAssertEqual(box.maxY, 15, accuracy: 0.000_001)
    }

    func testOverlapDetectionReturnsIntersectingPairs() {
        let template = FieldTemplateLibrary.fiveAside
        let first = template.makeLayout(named: "5A")
        let second = template.makeLayout(
            named: "5B",
            transform: FieldTransform(translation: Vector2D(dx: 5, dy: 0))
        )
        let third = template.makeLayout(
            named: "5C",
            transform: FieldTransform(translation: Vector2D(dx: 100, dy: 0))
        )

        let overlaps = FieldLayoutAnalysis.overlaps(in: [first, second, third])

        XCTAssertEqual(overlaps.count, 1)
        XCTAssertEqual(overlaps.first?.firstLayoutID, first.id)
        XCTAssertEqual(overlaps.first?.secondLayoutID, second.id)
    }

    func testPracticalLaneIssuesDetectNarrowSideBySideGap() {
        let template = FieldTemplateLibrary.fiveAside
        let first = template.makeLayout(named: "5A")
        let second = template.makeLayout(
            named: "5B",
            transform: FieldTransform(translation: Vector2D(dx: 44, dy: 0))
        )

        let issues = FieldLayoutAnalysis.practicalLaneIssues(in: [first, second], minimumLaneWidth: 6)

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.axis, .horizontal)
        XCTAssertEqual(issues.first?.laneWidthMeters ?? 0, 4, accuracy: 0.000_001)
    }
}
