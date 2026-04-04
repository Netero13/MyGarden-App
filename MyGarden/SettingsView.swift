import SwiftUI

// MARK: - Settings View
// App settings screen. Currently has:
// - Watering reminders toggle
// - Reminder time picker
// - About section
//
// Key concept: @AppStorage
// This is like @State but it saves to UserDefaults — a simple key-value
// store built into iOS. Unlike our JSON file (for complex plant data),
// UserDefaults is perfect for simple settings like on/off toggles.

struct SettingsView: View {

    // Access the plant store to schedule/cancel reminders
    @Environment(PlantStore.self) private var store

    // Settings saved to UserDefaults (persist across app launches)
    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @AppStorage("careActionEngineEnabled") private var careActionEngineEnabled = false
    @AppStorage("arboristEngineEnabled") private var arboristEngineEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 9
    @AppStorage("reminderMinute") private var reminderMinute = 0

    // Language — stored in UserDefaults as "AppleLanguages"
    // This overrides the system language for THIS app only.
    @State private var selectedLanguage: String = {
        if let langs = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
           let first = langs.first {
            return first.hasPrefix("uk") ? "uk" : "en"
        }
        return Locale.current.language.languageCode?.identifier ?? "en"
    }()

    // State
    @State private var notificationPermission: Bool = false
    @State private var showingPermissionAlert = false
    @State private var showingRestartAlert = false

    var body: some View {
        NavigationStack {
            Form {

                // -- Watering Reminders --
                Section {
                    Toggle(isOn: $remindersEnabled) {
                        Label(NSLocalizedString("Watering Reminders", comment: ""), systemImage: "bell.fill")
                    }
                    .onChange(of: remindersEnabled) {
                        handleReminderToggle()
                    }

                    if remindersEnabled {
                        // Show reminder time picker
                        HStack {
                            Label(NSLocalizedString("Remind me at", comment: ""), systemImage: "clock.fill")
                            Spacer()
                            Text(formattedTime)
                                .foregroundStyle(.blue)
                        }

                        // Hour and minute steppers
                        Stepper(String(format: NSLocalizedString("Hour: %d:00", comment: ""), reminderHour), value: $reminderHour, in: 6...22)
                            .onChange(of: reminderHour) {
                                rescheduleAllReminders()
                            }
                    }
                } header: {
                    Text(NSLocalizedString("Notifications", comment: ""))
                } footer: {
                    if remindersEnabled {
                        Text(String(format: NSLocalizedString("You'll get a reminder at %@ on the day each plant needs watering.", comment: ""), formattedTime))
                    } else {
                        Text(NSLocalizedString("Enable to get notified when your plants need watering.", comment: ""))
                    }
                }

                // -- Arborist Engine (AI/ML) --
                Section {
                    Toggle(isOn: $arboristEngineEnabled) {
                        Label(NSLocalizedString("Arborist Engine", comment: ""), systemImage: "brain.head.profile.fill")
                    }

                    if arboristEngineEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            arboristFeatureRow(icon: "cloud.sun.fill", text: NSLocalizedString("Weather-based insights", comment: ""), color: .blue)
                            arboristFeatureRow(icon: "chart.line.uptrend.xyaxis", text: NSLocalizedString("Patterns from your activity log", comment: ""), color: .purple)
                            arboristFeatureRow(icon: "sparkles", text: NSLocalizedString("Personalized recommendations", comment: ""), color: .orange)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(NSLocalizedString("AI Intelligence", comment: ""))
                } footer: {
                    if arboristEngineEnabled {
                        Text(NSLocalizedString("Arborist Engine analyzes weather, your activity history, and tree data to give you personalized, actionable insights for your garden.", comment: ""))
                    } else {
                        Text(NSLocalizedString("Enable smart insights that combine weather, your care history, and species data — tailored specifically to your garden.", comment: ""))
                    }
                }

                // -- CareAction Engine --
                Section {
                    Toggle(isOn: $careActionEngineEnabled) {
                        Label(NSLocalizedString("CareAction Engine", comment: ""), systemImage: "leaf.arrow.triangle.circlepath")
                    }
                    .onChange(of: careActionEngineEnabled) {
                        handleCareActionEngineToggle()
                    }

                    if careActionEngineEnabled {
                        // Show what types of alerts they'll get
                        VStack(alignment: .leading, spacing: 8) {
                            careActionRow(icon: "scissors", text: NSLocalizedString("Pruning reminders", comment: ""), color: .orange)
                            careActionRow(icon: "leaf.fill", text: NSLocalizedString("Fertilizing reminders", comment: ""), color: .green)
                            careActionRow(icon: "basket.fill", text: NSLocalizedString("Harvest alerts", comment: ""), color: .red)
                            careActionRow(icon: "ant.fill", text: NSLocalizedString("Pest treatment reminders", comment: ""), color: .red)
                            careActionRow(icon: "allergens", text: NSLocalizedString("Disease treatment reminders", comment: ""), color: .purple)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(NSLocalizedString("Smart Care", comment: ""))
                } footer: {
                    if careActionEngineEnabled {
                        Text(NSLocalizedString("You'll get a reminder on the 1st of each month when it's time to prune, fertilize, or harvest your plants.", comment: ""))
                    } else {
                        Text(NSLocalizedString("Get notified when it's time to prune, fertilize, or harvest — based on each plant's care calendar.", comment: ""))
                    }
                }

                // -- Stats --
                Section {
                    HStack {
                        Label(NSLocalizedString("Total Plants", comment: ""), systemImage: "leaf.fill")
                        Spacer()
                        Text("\(store.plants.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label(NSLocalizedString("Need Watering", comment: ""), systemImage: "drop.fill")
                        Spacer()
                        Text("\(store.plants.filter { $0.needsWatering }.count)")
                            .foregroundStyle(.red)
                    }

                    HStack {
                        Label(NSLocalizedString("Total Activities", comment: ""), systemImage: "clock.arrow.circlepath")
                        Spacer()
                        Text("\(store.plants.reduce(0) { $0 + $1.activities.count })")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(NSLocalizedString("Garden Stats", comment: ""))
                }

                // -- Weather Location --
                Section {
                    // GPS toggle — use device location automatically
                    Toggle(isOn: Binding(
                        get: { LocationManager.shared.useGPSForWeather },
                        set: { newValue in
                            LocationManager.shared.useGPSForWeather = newValue
                            if newValue {
                                // If turning on GPS, request permission if needed
                                if LocationManager.shared.isAuthorized {
                                    LocationManager.shared.requestLocation()
                                } else {
                                    LocationManager.shared.requestPermission()
                                }
                            }
                        }
                    )) {
                        Label(NSLocalizedString("Use My Location", comment: ""), systemImage: "location.fill")
                    }

                    // Show current location name
                    HStack {
                        Label(NSLocalizedString("Current", comment: ""), systemImage: "mappin.circle.fill")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(WeatherManager.shared.locationName)
                            .foregroundStyle(.secondary)
                    }

                    // Manual city picker — always available as a fallback
                    if !LocationManager.shared.useGPSForWeather {
                        NavigationLink {
                            WeatherLocationPicker()
                        } label: {
                            Label(NSLocalizedString("Choose City", comment: ""), systemImage: "globe")
                        }
                    }
                } header: {
                    Text(NSLocalizedString("Weather", comment: ""))
                } footer: {
                    if LocationManager.shared.useGPSForWeather {
                        Text(NSLocalizedString("Weather is based on your device's current location. Turn off to pick a city manually.", comment: ""))
                    } else {
                        Text(NSLocalizedString("Pick your city for accurate weather and gardening tips, or turn on location for automatic detection.", comment: ""))
                    }
                }

                // -- Your Name --
                Section {
                    HStack {
                        Label(NSLocalizedString("Name", comment: ""), systemImage: "person.fill")
                        Spacer()
                        TextField(NSLocalizedString("Your name", comment: ""), text: Binding(
                            get: { UserDefaults.standard.string(forKey: "userName") ?? "" },
                            set: { UserDefaults.standard.set($0, forKey: "userName") }
                        ))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(NSLocalizedString("Profile", comment: ""))
                } footer: {
                    Text(NSLocalizedString("Your name appears in the activity log.", comment: ""))
                }

                // -- Language --
                Section {
                    Picker(selection: $selectedLanguage) {
                        Text("English").tag("en")
                        Text("Українська").tag("uk")
                    } label: {
                        Label(NSLocalizedString("Language", comment: ""), systemImage: "globe")
                    }
                    .onChange(of: selectedLanguage) {
                        // Set the app's preferred language
                        UserDefaults.standard.set([selectedLanguage], forKey: "AppleLanguages")
                        UserDefaults.standard.synchronize()
                        showingRestartAlert = true
                    }
                } header: {
                    Text(NSLocalizedString("Language", comment: ""))
                } footer: {
                    Text(NSLocalizedString("Choose the app language. Restart required for full effect.", comment: ""))
                }

                // -- About --
                Section {
                    HStack {
                        Label(NSLocalizedString("App", comment: ""), systemImage: "tree.fill")
                        Spacer()
                        Text(NSLocalizedString("Arborist", comment: ""))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label(NSLocalizedString("Version", comment: ""), systemImage: "info.circle")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label(NSLocalizedString("Made in", comment: ""), systemImage: "flag.fill")
                        Spacer()
                        Text(NSLocalizedString("Ukraine 🇺🇦", comment: ""))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(NSLocalizedString("About", comment: ""))
                }
            }
            .navigationTitle(NSLocalizedString("Settings", comment: ""))
            .task {
                // Check notification permission on appear
                notificationPermission = await NotificationManager.shared.isAuthorized()
            }
            .alert(NSLocalizedString("Restart Required", comment: ""), isPresented: $showingRestartAlert) {
                Button(NSLocalizedString("OK", comment: "")) { }
            } message: {
                Text(NSLocalizedString("Please close and reopen the app for the language change to take effect.", comment: ""))
            }
            .alert(NSLocalizedString("Notifications Disabled", comment: ""), isPresented: $showingPermissionAlert) {
                Button(NSLocalizedString("Open Settings", comment: "")) {
                    // Open iOS Settings so user can enable notifications
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {
                    remindersEnabled = false
                }
            } message: {
                Text(NSLocalizedString("To receive watering reminders, please enable notifications in your iPhone Settings.", comment: ""))
            }
        }
    }

    // MARK: - Handle Reminder Toggle

    private func handleReminderToggle() {
        if remindersEnabled {
            // Request permission and schedule
            Task {
                let granted = await NotificationManager.shared.requestPermission()
                if granted {
                    notificationPermission = true
                    NotificationManager.shared.scheduleAllReminders(for: store.plants)
                } else {
                    // Permission denied — show alert to open settings
                    await MainActor.run {
                        showingPermissionAlert = true
                    }
                }
            }
        } else {
            // Cancel all reminders
            NotificationManager.shared.cancelAllReminders()
        }
    }

    // MARK: - Reschedule All Reminders
    // Called when the user changes the reminder time.

    private func rescheduleAllReminders() {
        if remindersEnabled {
            NotificationManager.shared.scheduleAllReminders(for: store.plants)
        }
        // CareAction Engine also uses reminderHour, so reschedule those too
        if careActionEngineEnabled {
            NotificationManager.shared.scheduleAllCareAlerts(for: store.plants)
        }
    }

    // MARK: - Handle CareAction Engine Toggle

    private func handleCareActionEngineToggle() {
        if careActionEngineEnabled {
            // Request permission (same as watering reminders)
            Task {
                let granted = await NotificationManager.shared.requestPermission()
                if granted {
                    NotificationManager.shared.scheduleAllCareAlerts(for: store.plants)
                } else {
                    await MainActor.run {
                        showingPermissionAlert = true
                        careActionEngineEnabled = false
                    }
                }
            }
        } else {
            // Cancel all care alerts
            NotificationManager.shared.cancelAllCareAlerts(for: store.plants)
        }
    }

    // MARK: - CareAction Engine Feature Row

    private func careActionRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Arborist Engine Feature Row

    private func arboristFeatureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Formatted Time

    private var formattedTime: String {
        String(format: "%d:%02d", reminderHour, reminderMinute)
    }
}

#Preview {
    SettingsView()
        .environment(PlantStore())
}
