import Foundation
import UserNotifications

// MARK: - Notification Manager
// Handles scheduling and managing watering reminder notifications.
//
// How iOS notifications work:
// 1. You ask the user: "Can I send you notifications?" (they can say no)
// 2. If they say yes, you SCHEDULE notifications in advance
// 3. iOS delivers them at the right time, even if the app is closed
//
// Each notification has a unique ID (we use the plant's ID).
// This way we can update or cancel a specific plant's reminder
// without affecting other plants.

class NotificationManager {

    // Singleton — one shared instance
    static let shared = NotificationManager()

    // Reference to iOS notification system
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Request Permission
    // Must be called before any notifications can be sent.
    // Shows the iOS popup: "MyGarden would like to send you notifications"
    // Returns true if the user said yes.

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("❌ Notification permission error: \(error)")
            return false
        }
    }

    // MARK: - Check if Authorized
    // Check current permission status without asking again.

    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Reminder for a Plant
    // Creates a notification that fires at the plant's next watering date.
    // If a reminder already exists for this plant, it's replaced.
    //
    // Example: Cherry was watered today, frequency is 7 days
    //          → schedules a notification for 7 days from now at 9:00 AM

    func scheduleReminder(for plant: Plant) {
        // Cancel any existing reminder for this plant first
        cancelReminder(for: plant.id)

        // Figure out when the next watering is
        guard let nextDate = plant.nextWateringDate else {
            // Plant was never watered — remind them NOW (well, in 1 minute)
            scheduleImmediateReminder(for: plant)
            return
        }

        // Don't schedule if the date is in the past
        if nextDate <= Date() {
            return
        }

        // Create the notification content (what the user sees)
        let content = UNMutableNotificationContent()
        content.title = "Time to water! 💧"
        content.body = plantReminderMessage(for: plant)
        content.sound = .default

        // Create the trigger (WHEN to show the notification)
        // We set it for 9:00 AM on the next watering day
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: nextDate
        )
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false  // one-time, we'll reschedule after watering
        )

        // Create the request with a unique ID based on the plant's ID
        let request = UNNotificationRequest(
            identifier: plant.id.uuidString,
            content: content,
            trigger: trigger
        )

        // Schedule it!
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule reminder for \(plant.name): \(error)")
            }
        }
    }

    // MARK: - Schedule Immediate Reminder
    // For plants that have never been watered — remind in 1 hour

    private func scheduleImmediateReminder(for plant: Plant) {
        let content = UNMutableNotificationContent()
        content.title = "Don't forget! 💧"
        content.body = "\(plant.displayName) hasn't been watered yet. Give it some water today!"
        content.sound = .default

        // Trigger after 1 hour (3600 seconds)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 3600,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: plant.id.uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Cancel Reminder for a Plant
    // Called when deleting a plant or turning off reminders.

    func cancelReminder(for plantID: UUID) {
        center.removePendingNotificationRequests(
            withIdentifiers: [plantID.uuidString]
        )
    }

    // MARK: - Cancel All Reminders
    // Called when the user turns off all reminders in settings.

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Schedule All Reminders
    // Loops through all plants and schedules reminders for each.
    // Called when the user turns on reminders, or at app startup.

    func scheduleAllReminders(for plants: [Plant]) {
        cancelAllReminders()
        for plant in plants {
            scheduleReminder(for: plant)
        }
    }

    // MARK: - Friendly Reminder Message
    // Creates a personalized message for each plant.

    private func plantReminderMessage(for plant: Plant) -> String {
        let name = plant.displayName
        let type = plant.type.rawValue.lowercased()

        let messages = [
            "Your \(type) \(name) is thirsty! Time to water.",
            "\(name) needs watering today. Don't let it go dry!",
            "Watering day for \(name)! 🌿",
            "Hey! Your \(name) could use some water today.",
        ]

        // Pick a random message for variety
        return messages.randomElement() ?? messages[0]
    }
}
