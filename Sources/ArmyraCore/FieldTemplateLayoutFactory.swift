import Foundation

public extension PitchSize {
    var playerCountLabel: String {
        switch self {
        case .fiveAside:
            return "5"
        case .sevenAside:
            return "7"
        case .nineAside:
            return "9"
        case .elevenAside:
            return "11"
        }
    }
}

public extension FieldTemplate {
    func makeLayout(
        named name: String,
        enabledMarkings: Set<LineMarking>? = nil,
        transform: FieldTransform = FieldTransform(),
        lockMode: PlacementLockMode = .center
    ) -> FieldLayout {
        let resolvedMarkings = (enabledMarkings ?? defaultMarkings).intersection(supportedMarkings)

        return FieldLayout(
            name: name,
            templateID: id,
            dimensions: dimensions,
            enabledMarkings: resolvedMarkings,
            transform: transform,
            lockMode: lockMode
        )
    }
}