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
    @AppStorage("careAlertsEnabled") private var careAlertsEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 9
    @AppStorage("reminderMinute") private var reminderMinute = 0

    // State
    @State private var notificationPermission: Bool = false
    @State private var showingPermissionAlert = false

    var body: some View {
        NavigationStack {
            Form {

                // -- Watering Reminders --
                Section {
                    Toggle(isOn: $remindersEnabled) {
                        Label("Watering Reminders", systemImage: "bell.fill")
                    }
                    .onChange(of: remindersEnabled) {
                        handleReminderToggle()
                    }

                    if remindersEnabled {
                        // Show reminder time picker
                        HStack {
                            Label("Remind me at", systemImage: "clock.fill")
                            Spacer()
                            Text(formattedTime)
                                .foregroundStyle(.blue)
                        }

                        // Hour and minute steppers
                        Stepper("Hour: \(reminderHour):00", value: $reminderHour, in: 6...22)
                            .onChange(of: reminderHour) {
                                rescheduleAllReminders()
                            }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if remindersEnabled {
                        Text("You'll get a reminder at \(formattedTime) on the day each plant needs watering.")
                    } else {
                        Text("Enable to get notified when your plants need watering.")
                    }
                }

                // -- Seasonal Care Alerts --
                Section {
                    Toggle(isOn: $careAlertsEnabled) {
                        Label("Seasonal Care Alerts", systemImage: "leaf.arrow.triangle.circlepath")
                    }
                    .onChange(of: careAlertsEnabled) {
                        handleCareAlertsToggle()
                    }

                    if careAlertsEnabled {
                        // Show what types of alerts they'll get
                        VStack(alignment: .leading, spacing: 8) {
                            careAlertRow(icon: "scissors", text: NSLocalizedString("Pruning reminders", comment: ""), color: .orange)
                            careAlertRow(icon: "leaf.fill", text: NSLocalizedString("Fertilizing reminders", comment: ""), color: .green)
                            careAlertRow(icon: "basket.fill", text: NSLocalizedString("Harvest alerts", comment: ""), color: .red)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Smart Care")
                } footer: {
                    if careAlertsEnabled {
                        Text("You'll get a reminder on the 1st of each month when it's time to prune, fertilize, or harvest your plants.")
                    } else {
                        Text("Get notified when it's time to prune, fertilize, or harvest — based on each plant's care calendar.")
                    }
                }

                // -- Stats --
                Section {
                    HStack {
                        Label("Total Plants", systemImage: "leaf.fill")
                        Spacer()
                        Text("\(store.plants.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Need Watering", systemImage: "drop.fill")
                        Spacer()
                        Text("\(store.plants.filter { $0.needsWatering }.count)")
                            .foregroundStyle(.red)
                    }

                    HStack {
                        Label("Total Activities", systemImage: "clock.arrow.circlepath")
                        Spacer()
                        Text("\(store.plants.reduce(0) { $0 + $1.activities.count })")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Garden Stats")
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
                        Label("Use My Location", systemImage: "location.fill")
                    }

                    // Show current location name
                    HStack {
                        Label("Current", systemImage: "mappin.circle.fill")
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
                            Label("Choose City", systemImage: "globe")
                        }
                    }
                } header: {
                    Text("Weather")
                } footer: {
                    if LocationManager.shared.useGPSForWeather {
                        Text("Weather is based on your device's current location. Turn off to pick a city manually.")
                    } else {
                        Text("Pick your city for accurate weather and gardening tips, or turn on location for automatic detection.")
                    }
                }

                // -- Family --
                Section {
                    NavigationLink {
                        FamilySettingsView()
                    } label: {
                        HStack {
                            Label("Family Members", systemImage: "person.3.fill")
                            Spacer()
                            if let member = FamilyManager.shared.activeMember {
                                Text("\(member.emoji) \(member.name)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Family")
                } footer: {
                    Text("Add family members so everyone can log activities with their name.")
                }

                // -- About --
                Section {
                    HStack {
                        Label("App", systemImage: "tree.fill")
                        Spacer()
                        Text("Arborist")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Made in", systemImage: "flag.fill")
                        Spacer()
                        Text("Ukraine 🇺🇦")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .task {
                // Check notification permission on appear
                notificationPermission = await NotificationManager.shared.isAuthorized()
            }
            .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    // Open iOS Settings so user can enable notifications
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {
                    remindersEnabled = false
                }
            } message: {
                Text("To receive watering reminders, please enable notifications for MyGarden in your iPhone Settings.")
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
        // Care alerts also use reminderHour, so reschedule those too
        if careAlertsEnabled {
            NotificationManager.shared.scheduleAllCareAlerts(for: store.plants)
        }
    }

    // MARK: - Handle Care Alerts Toggle

    private func handleCareAlertsToggle() {
        if careAlertsEnabled {
            // Request permission (same as watering reminders)
            Task {
                let granted = await NotificationManager.shared.requestPermission()
                if granted {
                    NotificationManager.shared.scheduleAllCareAlerts(for: store.plants)
                } else {
                    await MainActor.run {
                        showingPermissionAlert = true
                        careAlertsEnabled = false
                    }
                }
            }
        } else {
            // Cancel all care alerts
            NotificationManager.shared.cancelAllCareAlerts(for: store.plants)
        }
    }

    // MARK: - Care Alert Row
    // A small row showing one type of care alert with an icon.

    private func careAlertRow(icon: String, text: String, color: Color) -> some View {
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
