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

    // Track if language was auto-set (only do this ONCE on first ever launch)
    @AppStorage("hasAutoSetLanguage") private var hasAutoSetLanguage = false

    init() {
        // MARK: - Smart Language Default
        // On FIRST launch only, detect the user's region.
        // If they're in Ukraine (or their device language is Ukrainian),
        // set the app language to Ukrainian. Otherwise → English.
        //
        // This only runs ONCE. After that, the user can change
        // the language manually in Settings.
        if !UserDefaults.standard.bool(forKey: "hasAutoSetLanguage") {
            let regionCode = Locale.current.region?.identifier ?? ""
            let languageCode = Locale.current.language.languageCode?.identifier ?? ""

            if regionCode == "UA" || languageCode == "uk" {
                // User is in Ukraine or device is set to Ukrainian
                UserDefaults.standard.set(["uk"], forKey: "AppleLanguages")
            } else {
                // Everyone else gets English
                UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
            }
            UserDefaults.standard.set(true, forKey: "hasAutoSetLanguage")
            UserDefaults.standard.synchronize()
        }

        // MARK: - Migrate old UserDefaults key
        // "careAlertsEnabled" was renamed to "careActionEngineEnabled".
        // Carry over the old value so users don't lose their setting.
        if UserDefaults.standard.bool(forKey: "careAlertsEnabled") {
            UserDefaults.standard.set(true, forKey: "careActionEngineEnabled")
            UserDefaults.standard.removeObject(forKey: "careAlertsEnabled")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environment(store)
                    .onAppear {
                        store.rescheduleAllNotifications()
                        // CareAction Engine: auto-plan monthly tasks (only if engine is ON)
                        if UserDefaults.standard.bool(forKey: "careActionEngineEnabled") {
                            store.generatePlannedActivities()
                        }
                    }
            } else {
                OnboardingView {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
    }
}
