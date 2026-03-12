import XCTest
@testable import ArmyraCore

final class FieldTemplateLayoutFactoryTests: XCTestCase {
    func testMakeLayoutUsesFilteredMarkings() {
        let template = FieldTemplate(
            name: "Custom",
            pitchSize: .fiveAside,
            dimensions: PitchDimensions(lengthMeters: 40, widthMeters: 30),
            supportedMarkings: [.halfwayLine, .centerSpot],
            defaultMarkings: [.halfwayLine, .centerSpot]
        )

        let layout = template.makeLayout(
            named: "5A",
            enabledMarkings: [.halfwayLine, .goalArea]
        )

        XCTAssertEqual(layout.name, "5A")
        XCTAssertEqual(layout.enabledMarkings, [.halfwayLine])
    }

    func testPitchSizePlayerCountLabelMatchesExpectedNamingPrefix() {
        XCTAssertEqual(PitchSize.fiveAside.playerCountLabel, "5")
        XCTAssertEqual(PitchSize.sevenAside.playerCountLabel, "7")
        XCTAssertEqual(PitchSize.nineAside.playerCountLabel, "9")
        XCTAssertEqual(PitchSize.elevenAside.playerCountLabel, "11")
    }
}