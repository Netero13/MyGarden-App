import Foundation
import UserNotifications

// MARK: - Notification Manager
// Handles TWO types of notifications:
//
// 1. WATERING REMINDERS — "Your Cherry needs watering today!"
//    Fires on the day each plant's next watering is due.
//
// 2. SEASONAL CARE ALERTS — "Time to prune your Cherry!"
//    Fires on the 1st of the month when it's time to prune,
//    fertilize, or harvest a specific plant.
//
// How iOS notifications work:
// 1. You ask the user: "Can I send you notifications?" (they can say no)
// 2. If they say yes, you SCHEDULE notifications in advance
// 3. iOS delivers them at the right time, even if the app is closed
//
// Each notification has a unique ID (we use the plant's UUID).
// For care alerts, we add a suffix like "-prune-3" (prune in March).

class NotificationManager {

    // Singleton — one shared instance used everywhere
    static let shared = NotificationManager()

    // Reference to iOS notification system
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Request Permission
    // Must be called before any notifications can be sent.
    // Shows the iOS popup: "Arborist would like to send you notifications"
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

    // MARK: - Get User's Reminder Hour
    // Reads the hour the user picked in Settings.
    // Defaults to 9:00 AM if not set.
    //
    // Why read from UserDefaults?
    // Because SettingsView stores the value with @AppStorage("reminderHour"),
    // which is just a wrapper around UserDefaults. We read it directly here
    // so we don't need to pass the hour around everywhere.

    private var reminderHour: Int {
        let hour = UserDefaults.standard.integer(forKey: "reminderHour")
        // UserDefaults returns 0 for unset keys, so default to 9
        return hour == 0 ? 9 : hour
    }

    // ════════════════════════════════════════════════════════════════
    // MARK: - WATERING REMINDERS
    // ════════════════════════════════════════════════════════════════

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
            // Plant was never watered — remind them soon
            scheduleImmediateReminder(for: plant)
            return
        }

        // Don't schedule if the date is in the past
        if nextDate <= Date() {
            return
        }

        // Create the notification content (what the user sees)
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Time to water! 💧", comment: "")
        content.body = plantReminderMessage(for: plant)
        content.sound = .default

        // Create the trigger — fire at the user's chosen hour on the watering day
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: nextDate
        )
        dateComponents.hour = reminderHour
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
        content.title = NSLocalizedString("Don't forget! 💧", comment: "")
        content.body = String(
            format: NSLocalizedString("%@ hasn't been watered yet. Give it some water today!", comment: ""),
            plant.displayName
        )
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

    func cancelReminder(for plantID: UUID) {
        center.removePendingNotificationRequests(
            withIdentifiers: [plantID.uuidString]
        )
    }

    // MARK: - Cancel All Watering Reminders
    // Note: this also cancels care alerts. Use with care.

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Schedule All Watering Reminders
    // Loops through all plants and schedules reminders for each.
    // Called when the user turns on reminders, changes time, or at app startup.

    func scheduleAllReminders(for plants: [Plant]) {
        // Only cancel watering reminders (keep care alerts)
        let wateringIDs = plants.map { $0.id.uuidString }
        center.removePendingNotificationRequests(withIdentifiers: wateringIDs)

        for plant in plants {
            scheduleReminder(for: plant)
        }
    }

    // MARK: - Friendly Reminder Message

    private func plantReminderMessage(for plant: Plant) -> String {
        let name = plant.displayName

        let messages = [
            String(format: NSLocalizedString("Your %@ is thirsty! Time to water.", comment: ""), name),
            String(format: NSLocalizedString("%@ needs watering today.", comment: ""), name),
            String(format: NSLocalizedString("Watering day for %@! 🌿", comment: ""), name),
            String(format: NSLocalizedString("Hey! Your %@ could use some water today.", comment: ""), name),
        ]

        return messages.randomElement() ?? messages[0]
    }

    // ════════════════════════════════════════════════════════════════
    // MARK: - SEASONAL CARE ALERTS
    // ════════════════════════════════════════════════════════════════
    //
    // These are the "smart" notifications that make Arborist special.
    // On the 1st of each relevant month, the user gets alerts like:
    //   "🌿 Time to prune your Cherry! Cut dead branches..."
    //   "🧪 Fertilize your Apple this month with nitrogen fertilizer"
    //   "🍎 Harvest time for Raspberry! Enjoy your berries!"
    //
    // We schedule alerts for the NEXT 12 months so they're set up in advance.
    // Each alert ID looks like: "plantUUID-prune-3" (prune in March)

    // MARK: - Schedule Care Alerts for One Plant
    // Looks up the plant's TreeIntelligence and schedules alerts
    // for pruning, fertilizing, and harvesting months.

    func scheduleCareAlerts(for plant: Plant) {
        // Look up this plant's intelligence data from the encyclopedia
        guard let species = TreeEncyclopedia.find(name: plant.name) else { return }
        let intel = species.intelligence

        // Cancel any existing care alerts for this plant
        cancelCareAlerts(for: plant.id)

        let now = Date()
        let currentMonth = Calendar.current.component(.month, from: now)
        let currentYear = Calendar.current.component(.year, from: now)

        // -- Pruning alerts --
        for month in intel.pruningMonths {
            let id = "\(plant.id.uuidString)-prune-\(month)"
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("Time to prune! ✂️", comment: "")
            content.body = String(
                format: NSLocalizedString("Your %@ should be pruned this month. %@", comment: ""),
                plant.displayName,
                intel.pruningTips
            )
            content.sound = .default

            scheduleMonthlyAlert(id: id, month: month, content: content,
                                 currentMonth: currentMonth, currentYear: currentYear)
        }

        // -- Fertilizing alerts --
        for month in intel.fertilizerMonths {
            let id = "\(plant.id.uuidString)-fert-\(month)"
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("Fertilizing time! 🧪", comment: "")
            content.body = String(
                format: NSLocalizedString("Feed your %@ this month. Recommended: %@", comment: ""),
                plant.displayName,
                intel.fertilizerType
            )
            content.sound = .default

            scheduleMonthlyAlert(id: id, month: month, content: content,
                                 currentMonth: currentMonth, currentYear: currentYear)
        }

        // -- Harvest alerts (only for fruit trees & berry bushes) --
        if let harvestMonths = intel.harvestMonths {
            for month in harvestMonths {
                let id = "\(plant.id.uuidString)-harvest-\(month)"
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("Harvest time! 🍎", comment: "")
                content.body = String(
                    format: NSLocalizedString("Your %@ is ready to harvest this month. Enjoy!", comment: ""),
                    plant.displayName
                )
                content.sound = .default

                scheduleMonthlyAlert(id: id, month: month, content: content,
                                     currentMonth: currentMonth, currentYear: currentYear)
            }
        }

        // -- Pest treatment alerts --
        for month in intel.pestTreatmentMonths {
            let id = "\(plant.id.uuidString)-pest-\(month)"
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("Pest treatment time! 🐛", comment: "")
            content.body = String(
                format: NSLocalizedString("Treat your %@ for pests this month. %@", comment: ""),
                plant.displayName,
                intel.pestTreatmentTip
            )
            content.sound = .default

            scheduleMonthlyAlert(id: id, month: month, content: content,
                                 currentMonth: currentMonth, currentYear: currentYear)
        }

        // -- Disease treatment alerts --
        for month in intel.diseaseTreatmentMonths {
            let id = "\(plant.id.uuidString)-disease-\(month)"
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("Disease prevention time! 🛡️", comment: "")
            content.body = String(
                format: NSLocalizedString("Treat your %@ for diseases this month. %@", comment: ""),
                plant.displayName,
                intel.diseaseTreatmentTip
            )
            content.sound = .default

            scheduleMonthlyAlert(id: id, month: month, content: content,
                                 currentMonth: currentMonth, currentYear: currentYear)
        }
    }

    // MARK: - Schedule a Single Monthly Alert
    // Fires on the 1st of the given month at the user's reminder hour.
    // If the month is in the past this year, schedules for next year.
    //
    // Example: It's April. Pruning month is March.
    //          → schedules for March 1st NEXT year.
    //          Pruning month is June → schedules for June 1st THIS year.

    private func scheduleMonthlyAlert(
        id: String,
        month: Int,
        content: UNMutableNotificationContent,
        currentMonth: Int,
        currentYear: Int
    ) {
        // Decide year: if the month already passed, schedule for next year
        let year = month <= currentMonth ? currentYear + 1 : currentYear

        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = reminderHour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule care alert \(id): \(error)")
            }
        }
    }

    // MARK: - Cancel Care Alerts for a Plant
    // Removes all prune/fertilize/harvest/pest/disease alerts for a specific plant.
    // We generate all possible IDs and remove them in bulk.

    func cancelCareAlerts(for plantID: UUID) {
        var ids: [String] = []
        let base = plantID.uuidString

        // Generate all possible IDs for months 1-12
        for month in 1...12 {
            ids.append("\(base)-prune-\(month)")
            ids.append("\(base)-fert-\(month)")
            ids.append("\(base)-harvest-\(month)")
            ids.append("\(base)-pest-\(month)")
            ids.append("\(base)-disease-\(month)")
        }

        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Schedule All Care Alerts (Smart Limit)
    // iOS only allows 64 pending notifications total.
    // Watering reminders get ~20 slots. That leaves ~40 for care alerts.
    // Instead of scheduling ALL months for ALL plants (could be 200+),
    // we collect all upcoming care alerts, sort by date (soonest first),
    // and schedule only the top 40. This way the most urgent alerts always fire.

    private let careAlertBudget = 40  // max care notifications (out of 64 total)

    func scheduleAllCareAlerts(for plants: [Plant]) {
        // Step 1: Cancel all existing care alerts
        for plant in plants {
            cancelCareAlerts(for: plant.id)
        }

        // Step 2: Collect ALL possible care alerts with their dates
        let now = Date()
        let currentMonth = Calendar.current.component(.month, from: now)
        let currentYear = Calendar.current.component(.year, from: now)

        // A temporary struct to sort alerts by date before scheduling
        struct PendingAlert {
            let id: String
            let content: UNMutableNotificationContent
            let month: Int
            let year: Int
        }

        var pending: [PendingAlert] = []

        for plant in plants {
            guard let species = TreeEncyclopedia.find(name: plant.name) else { continue }
            let intel = species.intelligence

            // Helper: create a pending alert
            func add(suffix: String, month: Int, title: String, body: String) {
                let id = "\(plant.id.uuidString)-\(suffix)-\(month)"
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                let year = month <= currentMonth ? currentYear + 1 : currentYear
                pending.append(PendingAlert(id: id, content: content, month: month, year: year))
            }

            for month in intel.pruningMonths {
                add(suffix: "prune", month: month,
                    title: NSLocalizedString("Time to prune! ✂️", comment: ""),
                    body: String(format: NSLocalizedString("Your %@ should be pruned this month. %@", comment: ""),
                                 plant.displayName, intel.pruningTips))
            }

            for month in intel.fertilizerMonths {
                add(suffix: "fert", month: month,
                    title: NSLocalizedString("Fertilizing time! 🧪", comment: ""),
                    body: String(format: NSLocalizedString("Feed your %@ this month. Recommended: %@", comment: ""),
                                 plant.displayName, intel.fertilizerType))
            }

            if let harvestMonths = intel.harvestMonths {
                for month in harvestMonths {
                    add(suffix: "harvest", month: month,
                        title: NSLocalizedString("Harvest time! 🍎", comment: ""),
                        body: String(format: NSLocalizedString("Your %@ is ready to harvest this month. Enjoy!", comment: ""),
                                     plant.displayName))
                }
            }

            for month in intel.pestTreatmentMonths {
                add(suffix: "pest", month: month,
                    title: NSLocalizedString("Pest treatment time! 🐛", comment: ""),
                    body: String(format: NSLocalizedString("Treat your %@ for pests this month. %@", comment: ""),
                                 plant.displayName, intel.pestTreatmentTip))
            }

            for month in intel.diseaseTreatmentMonths {
                add(suffix: "disease", month: month,
                    title: NSLocalizedString("Disease prevention time! 🛡️", comment: ""),
                    body: String(format: NSLocalizedString("Treat your %@ for diseases this month. %@", comment: ""),
                                 plant.displayName, intel.diseaseTreatmentTip))
            }
        }

        // Step 3: Sort by date (soonest first) and take only the budget
        pending.sort { a, b in
            if a.year != b.year { return a.year < b.year }
            return a.month < b.month
        }

        let toSchedule = pending.prefix(careAlertBudget)

        // Step 4: Schedule the top alerts
        for alert in toSchedule {
            scheduleMonthlyAlert(id: alert.id, month: alert.month, content: alert.content,
                                 currentMonth: currentMonth, currentYear: currentYear)
        }
    }

    // MARK: - Cancel All Care Alerts
    // Removes all care alerts for all plants.

    func cancelAllCareAlerts(for plants: [Plant]) {
        for plant in plants {
            cancelCareAlerts(for: plant.id)
        }
    }
}
