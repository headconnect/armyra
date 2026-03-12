import SwiftUI

@main
struct ArmyraApp: App {
    @StateObject private var store: ProjectStore
    private let initialTab: RootTab

    init() {
        let configuredStore = ProjectStore.preview
        let launchConfiguration = AppLaunchConfiguration.current
        self.initialTab = launchConfiguration.initialTab
        launchConfiguration.apply(to: configuredStore)
        _store = StateObject(wrappedValue: configuredStore)
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, initialTab: initialTab)
        }
    }
}
