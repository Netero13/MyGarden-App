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

                // -- About --
                Section {
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
