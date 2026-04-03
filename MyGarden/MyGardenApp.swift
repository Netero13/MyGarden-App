import SwiftUI

@main
struct MyGardenApp: App {

    // Create ONE PlantStore for the entire app.
    // @State keeps it alive for the app's lifetime.
    // All screens will share this same store.
    @State private var store = PlantStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Pass the store to ALL child views via the environment.
                // Any screen can now access it with @Environment(PlantStore.self)
                .environment(store)
        }
    }
}
