import XCTest
@testable import ArmyraCore

final class FieldLayoutValidatorTests: XCTestCase {
    func testInvalidDimensionsAreRejected() {
        let template = FieldTemplateLibrary.sevenAside
        let layout = FieldLayout(
            name: "7A",
            templateID: template.id,
            dimensions: PitchDimensions(lengthMeters: 0, widthMeters: 40),
            enabledMarkings: []
        )

        XCTAssertThrowsError(try FieldLayoutValidator.validate(layout: layout, template: template)) { error in
            XCTAssertEqual(error as? FieldValidationError, .negativeOrZeroDimension)
        }
    }

    func testUnsupportedMarkingsAreRejected() {
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

        XCTAssertThrowsError(try FieldLayoutValidator.validate(layout: layout, template: template)) { error in
            XCTAssertEqual(error as? FieldValidationError, .unsupportedMarking(.goalArea))
        }
    }
}