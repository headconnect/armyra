import XCTest

final class ArmyraScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureScreenshotGallery() throws {
        for scenario in ScreenshotScenario.allCases {
            let app = XCUIApplication()
            app.launchEnvironment["ARMYRA_SCREENSHOT_SCENE"] = scenario.sceneName
            app.launch()

            scenario.prepareForCapture(in: app)
            XCTAssertTrue(
                scenario.readinessElement(in: app).waitForExistence(timeout: 10),
                "Expected \(scenario.expectedLabel) screen to be visible for screenshot capture."
            )

            saveScreenshot(for: scenario)
            app.terminate()
        }
    }

    private func saveScreenshot(for scenario: ScreenshotScenario) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = scenario.fileName
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

private enum ScreenshotScenario: CaseIterable {
    case projects
    case planning
    case planningScan
    case chalking
    case chalkingActive

    var sceneName: String {
        switch self {
        case .projects:
            return "projects"
        case .planning:
            return "planning"
        case .planningScan:
            return "planningScan"
        case .chalking:
            return "chalking"
        case .chalkingActive:
            return "chalkingActive"
        }
    }

    var fileName: String {
        switch self {
        case .projects:
            return "01-projects"
        case .planning:
            return "02-planning"
        case .planningScan:
            return "03-planning-scan"
        case .chalking:
            return "04-chalking-preflight"
        case .chalkingActive:
            return "05-chalking-active"
        }
    }

    var expectedLabel: String {
        switch self {
        case .projects:
            return "Projects"
        case .planning, .planningScan:
            return "Planning"
        case .chalking, .chalkingActive:
            return "Chalking"
        }
    }

    func prepareForCapture(in app: XCUIApplication) {
        guard self == .chalkingActive else { return }

        let endButton = app.buttons["End Session"]
        var attempts = 0
        while !endButton.exists && attempts < 6 {
            app.swipeUp()
            attempts += 1
        }
    }

    func readinessElement(in app: XCUIApplication) -> XCUIElement {
        switch self {
        case .projects:
            return app.navigationBars["Projects"]
        case .planning:
            return app.navigationBars["Planning"]
        case .planningScan:
            return app.staticTexts["Current Scan Task"]
        case .chalking:
            return app.navigationBars["Chalking"]
        case .chalkingActive:
            return app.buttons["End Session"]
        }
    }
}
