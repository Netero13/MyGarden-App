import SwiftUI

// MARK: - Content View
// The root view of the app. Now uses a TabView (bottom tab bar)
// with two tabs: the plant list and settings.
//
// Key concept: TabView
// A TabView shows a bar at the bottom with icons.
// Tapping each icon switches to a different screen.
// Most iOS apps use this pattern (Instagram, Settings, etc.)

struct ContentView: View {
    var body: some View {
        TabView {
            // Tab 1: Plant List (the main screen)
            PlantListView()
                .tabItem {
                    Label("My Garden", systemImage: "leaf.fill")
                }

            // Tab 2: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(PlantStore())
}
