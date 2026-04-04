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
            // Tab 1: Trees & Bushes list (the main screen)
            PlantListView()
                .tabItem {
                    Label(NSLocalizedString("Trees", comment: ""), systemImage: "tree.fill")
                }

            EncyclopediaView()
                .tabItem {
                    Label(NSLocalizedString("Encyclopedia", comment: ""), systemImage: "books.vertical.fill")
                }

            GardenMapView()
                .tabItem {
                    Label(NSLocalizedString("Garden", comment: ""), systemImage: "map.fill")
                }

            ActivityFeedView()
                .tabItem {
                    Label(NSLocalizedString("Activity", comment: ""), systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Label(NSLocalizedString("Settings", comment: ""), systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(PlantStore())
}
