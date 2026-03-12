import SwiftUI

struct RootView: View {
    @ObservedObject var store: ProjectStore

    var body: some View {
        TabView {
            ProjectsView(store: store)
                .tabItem {
                    Label("Projects", systemImage: "square.grid.2x2")
                }

            PlanningView(store: store)
                .tabItem {
                    Label("Planning", systemImage: "ruler")
                }

            ChalkingView(store: store)
                .tabItem {
                    Label("Chalking", systemImage: "figure.walk")
                }
        }
    }
}