import Foundation

public enum FieldTemplateLibrary {
    public static let all: [FieldTemplate] = [
        fiveAside,
        sevenAside,
        nineAside,
        elevenAside,
    ]

    public static let fiveAside = FieldTemplate(
        name: "5-a-side",
        pitchSize: .fiveAside,
        dimensions: PitchDimensions(
            lengthMeters: 40,
            widthMeters: 30,
            centerCircleRadiusMeters: 3,
            penaltyAreaDepthMeters: 6,
            penaltyAreaWidthMeters: 12,
            goalAreaDepthMeters: 3,
            goalAreaWidthMeters: 8,
            penaltySpotDistanceMeters: 7
        ),
        supportedMarkings: Set(LineMarking.allCases),
        defaultMarkings: [.halfwayLine, .centerCircle, .centerSpot, .penaltyArea, .goalArea, .penaltySpot]
    )

    public static let sevenAside = FieldTemplate(
        name: "7-a-side",
        pitchSize: .sevenAside,
        dimensions: PitchDimensions(
            lengthMeters: 60,
            widthMeters: 40,
            centerCircleRadiusMeters: 6,
            penaltyAreaDepthMeters: 10,
            penaltyAreaWidthMeters: 24,
            goalAreaDepthMeters: 5,
            goalAreaWidthMeters: 14,
            penaltySpotDistanceMeters: 8
        ),
        supportedMarkings: Set(LineMarking.allCases),
        defaultMarkings: [.halfwayLine, .centerCircle, .centerSpot, .penaltyArea, .goalArea, .penaltySpot]
    )

    public static let nineAside = FieldTemplate(
        name: "9-a-side",
        pitchSize: .nineAside,
        dimensions: PitchDimensions(
            lengthMeters: 80,
            widthMeters: 50,
            centerCircleRadiusMeters: 7.5,
            penaltyAreaDepthMeters: 13,
            penaltyAreaWidthMeters: 30,
            goalAreaDepthMeters: 5.5,
            goalAreaWidthMeters: 18,
            penaltySpotDistanceMeters: 9
        ),
        supportedMarkings: Set(LineMarking.allCases),
        defaultMarkings: [.halfwayLine, .centerCircle, .centerSpot, .penaltyArea, .goalArea, .penaltySpot]
    )

    public static let elevenAside = FieldTemplate(
        name: "11-a-side",
        pitchSize: .elevenAside,
        dimensions: PitchDimensions(
            lengthMeters: 105,
            widthMeters: 68,
            centerCircleRadiusMeters: 9.15,
            penaltyAreaDepthMeters: 16.5,
            penaltyAreaWidthMeters: 40.32,
            goalAreaDepthMeters: 5.5,
            goalAreaWidthMeters: 18.32,
            penaltySpotDistanceMeters: 11
        ),
        supportedMarkings: Set(LineMarking.allCases),
        defaultMarkings: [.halfwayLine, .centerCircle, .centerSpot, .penaltyArea, .goalArea, .penaltySpot]
    )
}