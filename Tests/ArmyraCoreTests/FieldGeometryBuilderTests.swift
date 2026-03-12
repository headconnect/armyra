import XCTest
@testable import ArmyraCore

final class FieldGeometryBuilderTests: XCTestCase {
    func testFiveAsideGeneratesBoundaryAndInteriorMarkings() {
        let template = FieldTemplateLibrary.fiveAside
        let layout = FieldLayout(
            name: "5A",
            templateID: template.id,
            dimensions: template.dimensions,
            enabledMarkings: template.defaultMarkings
        )

        let geometry = FieldGeometryBuilder.build(for: layout)

        XCTAssertEqual(geometry.boundary.count, 4)
        XCTAssertEqual(geometry.interiorLines.count, 13)
        XCTAssertEqual(geometry.circles.count, 4)
        XCTAssertEqual(geometry.guidePath.count, geometry.guideSegments.count)
    }

    func testRotationAndTranslationAreApplied() throws {
        let template = FieldTemplateLibrary.fiveAside
        let layout = FieldLayout(
            name: "5A",
            templateID: template.id,
            dimensions: template.dimensions,
            enabledMarkings: [],
            transform: FieldTransform(
                translation: Vector2D(dx: 10, dy: 5),
                rotationRadians: .pi / 2
            )
        )

        let geometry = FieldGeometryBuilder.build(for: layout)
        let start = try XCTUnwrap(geometry.boundary.first?.start)

        XCTAssertEqual(start.x, -5, accuracy: 0.000_001)
        XCTAssertEqual(start.y, -15, accuracy: 0.000_001)
    }
}
