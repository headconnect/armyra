import Foundation

public enum FieldValidationError: Error, Equatable, Sendable {
    case unsupportedMarking(LineMarking)
    case negativeOrZeroDimension
}

public enum FieldLayoutValidator {
    public static func validate(
        layout: FieldLayout,
        template: FieldTemplate
    ) throws {
        guard layout.dimensions.lengthMeters > 0, layout.dimensions.widthMeters > 0 else {
            throw FieldValidationError.negativeOrZeroDimension
        }

        for marking in layout.enabledMarkings where !template.supportedMarkings.contains(marking) {
            throw FieldValidationError.unsupportedMarking(marking)
        }
    }
}