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
                    Label("Trees", systemImage: "tree.fill")
                }

            // Tab 2: Tree Encyclopedia (browsable catalog)
            // Users come here to DISCOVER species before planting.
            // Think of it as a "shopping catalog" for trees & bushes.
            CatalogView()
                .tabItem {
                    Label("Catalog", systemImage: "books.vertical.fill")
                }

            // Tab 3: Garden Map (visual bird's-eye view)
            GardenMapView()
                .tabItem {
                    Label("Garden", systemImage: "map.fill")
                }

            // Tab 4: Activity Feed (all activities across all plants)
            ActivityFeedView()
                .tabItem {
                    Label("Activity", systemImage: "clock.arrow.circlepath")
                }

            // Tab 5: Settings
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
