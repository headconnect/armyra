import Foundation

enum ScreenshotScene: String {
    case projects
    case planning
    case planningScan
    case chalking
    case chalkingActive
}

@MainActor
struct AppLaunchConfiguration {
    let screenshotScene: ScreenshotScene?

    static var current: AppLaunchConfiguration {
        let environment = ProcessInfo.processInfo.environment
        let scene = environment["ARMYRA_SCREENSHOT_SCENE"].flatMap(ScreenshotScene.init(rawValue:))
        return AppLaunchConfiguration(screenshotScene: scene)
    }

    var initialTab: RootTab {
        switch screenshotScene {
        case .projects, .none:
            return .projects
        case .planning, .planningScan:
            return .planning
        case .chalking, .chalkingActive:
            return .chalking
        }
    }

    func apply(to store: ProjectStore) {
        guard let screenshotScene else { return }

        switch screenshotScene {
        case .projects:
            break
        case .planning:
            if let firstLayoutID = store.selectedProject?.layouts.first?.id {
                store.selectLayout(firstLayoutID)
            }
        case .planningScan:
            store.startVenueScanSession()
        case .chalking:
            if let firstLayoutID = store.selectedProject?.layouts.first?.id {
                store.selectChalkingLayout(firstLayoutID)
            }
        case .chalkingActive:
            if let firstLayoutID = store.selectedProject?.layouts.first?.id {
                store.selectChalkingLayout(firstLayoutID)
            }
            store.startChalkingSession()
        }
    }
}
