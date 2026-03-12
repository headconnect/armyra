import Testing
@testable import ArmyraCore

struct FieldLayoutValidatorTests {
    @Test func invalidDimensionsAreRejected() {
        let template = FieldTemplateLibrary.sevenAside
        let layout = FieldLayout(
            name: "7A",
            templateID: template.id,
            dimensions: PitchDimensions(lengthMeters: 0, widthMeters: 40),
            enabledMarkings: []
        )

        #expect(throws: FieldValidationError.negativeOrZeroDimension) {
            try FieldLayoutValidator.validate(layout: layout, template: template)
        }
    }

    @Test func unsupportedMarkingsAreRejected() {
        let template = FieldTemplate(
            name: "Minimal",
            pitchSize: .fiveAside,
            dimensions: PitchDimensions(lengthMeters: 40, widthMeters: 30),
            supportedMarkings: [.halfwayLine],
            defaultMarkings: [.halfwayLine]
        )
        let layout = FieldLayout(
            name: "5B",
            templateID: template.id,
            dimensions: template.dimensions,
            enabledMarkings: [.goalArea]
        )

        #expect(throws: FieldValidationError.unsupportedMarking(.goalArea)) {
            try FieldLayoutValidator.validate(layout: layout, template: template)
        }
    }
}