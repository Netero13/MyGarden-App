import SwiftUI

// MARK: - App Entry Point
// This is where Arborist starts. It decides what to show:
// - First launch → Onboarding screen (welcome + profile setup)
// - Returning user → Main app (ContentView with tabs)
//
// Key concept: @AppStorage
// We use @AppStorage("hasCompletedOnboarding") to remember whether
// the user has seen the welcome screen. This value survives app restarts
// because it's stored in UserDefaults (like a tiny database for settings).

@main
struct ArboristApp: App {

    // Create ONE PlantStore for the entire app
    @State private var store = PlantStore()

    // Track whether onboarding has been completed
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                // Returning user — show the main app
                ContentView()
                    .environment(store)
            } else {
                // First launch — show the welcome screen
                OnboardingView {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
    }
}
