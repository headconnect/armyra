import Testing
@testable import ArmyraCore

struct FieldGeometryBuilderTests {
    @Test func fiveAsideGeneratesBoundaryAndInteriorMarkings() {
        let template = FieldTemplateLibrary.fiveAside
        let layout = FieldLayout(
            name: "5A",
            templateID: template.id,
            dimensions: template.dimensions,
            enabledMarkings: template.defaultMarkings
        )

        let geometry = FieldGeometryBuilder.build(for: layout)

        #expect(geometry.boundary.count == 4)
        #expect(geometry.interiorLines.count == 13)
        #expect(geometry.circles.count == 4)
    }

    @Test func rotationAndTranslationAreApplied() {
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

        #expect(geometry.boundary.first?.start == Point2D(x: -5, y: -15))
    }
}