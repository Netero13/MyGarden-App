import SwiftUI

// MARK: - Content View
// This is the "root" view — the first thing the app shows.
// Before, it showed a welcome screen. Now it shows the plant list!
// As we add more screens (detail view, add plant form), they'll
// be navigated TO from here.

struct ContentView: View {
    var body: some View {
        PlantListView()
    }
}

#Preview {
    ContentView()
}
