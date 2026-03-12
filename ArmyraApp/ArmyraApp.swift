import SwiftUI

@main
struct ArmyraApp: App {
    @StateObject private var store = ProjectStore.preview

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
    }
}