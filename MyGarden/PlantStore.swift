import Foundation
import SwiftUI

// MARK: - Plant Store
// This is the "brain" that manages all your plants.
// It handles: loading, saving, adding, deleting, and updating plants.
//
// Key concept: @Observable
// This is a Swift macro that makes SwiftUI automatically update the screen
// whenever any property in this class changes. So when you add or delete a plant,
// the list refreshes instantly — no manual refresh needed.
//
// Key concept: Class vs Struct
// PlantStore is a CLASS (not a struct) because we need ONE shared instance
// that multiple screens can read and write to. If it were a struct, each screen
// would get its own copy, and changes wouldn't sync between screens.

@Observable
class PlantStore {

    // The main list of plants. Whenever this changes, the UI updates.
    var plants: [Plant] = []

    // MARK: - Init (runs when the app starts)
    // Tries to load saved plants from disk. If none exist (first launch),
    // loads the sample data so the app isn't empty.
    init() {
        if let savedPlants = Self.load() {
            plants = savedPlants
        } else {
            // First launch — start with an empty garden.
            // The user will add their own plants via the + button.
            // (Sample data was removed for App Store — reviewers expect a clean start.)
            plants = []
        }
    }

    // MARK: - Add a Plant
    func add(_ plant: Plant) {
        plants.append(plant)
        save()
        scheduleReminderIfEnabled(for: plant)
        scheduleCareActionsIfEnabled(for: plant)
        // CareAction Engine: generate planned activities for this new plant (mid-month addition)
        if UserDefaults.standard.bool(forKey: "careActionEngineEnabled") {
            generatePlannedActivitiesForNewPlant(plant)
        }
    }

    // MARK: - Delete a Plant
    // 'IndexSet' is what SwiftUI gives us when the user swipes to delete.
    // It tells us WHICH items (by position) to remove.
    func delete(at offsets: IndexSet) {
        // Cancel ALL notifications (watering + care alerts) for deleted plants
        for offset in offsets {
            let id = plants[offset].id
            NotificationManager.shared.cancelReminder(for: id)
            NotificationManager.shared.cancelCareActionAlerts(for: id)
        }
        plants.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Delete by ID
    // Sometimes we know the plant's ID but not its position.
    func delete(id: UUID) {
        NotificationManager.shared.cancelReminder(for: id)
        NotificationManager.shared.cancelCareActionAlerts(for: id)
        plants.removeAll { $0.id == id }
        save()
    }

    // MARK: - Update a Plant
    // Finds the plant by ID and replaces it with the updated version.
    func update(_ plant: Plant) {
        if let index = plants.firstIndex(where: { $0.id == plant.id }) {
            plants[index] = plant
            save()
            scheduleReminderIfEnabled(for: plant)
            scheduleCareActionsIfEnabled(for: plant)
        }
    }

    // MARK: - Water a Plant
    // Updates lastWatered AND logs a watering activity in one step.
    // This ensures both changes happen on the SAME copy of the plant
    // (the store's copy) and get saved to disk together.
    func water(id: UUID) {
        if let index = plants.firstIndex(where: { $0.id == id }) {
            plants[index].lastWatered = Date()

            // Log the watering as an activity (so it shows in Activity Feed)
            let activity = CareActivity(
                type: .watered,
                date: Date(),
                note: nil,
                memberName: UserDefaults.standard.string(forKey: "userName")
            )
            plants[index].activities.append(activity)

            save()
            scheduleReminderIfEnabled(for: plants[index])
        }
    }

    // MARK: - Prune a Plant
    // Same pattern as water() — updates state + logs activity in one step.
    // NEW: If a "planned" pruning activity exists this month, transitions it to "done"
    // instead of creating a duplicate. This is the planned→done flow.
    func prune(id: UUID, note: String? = nil, photoID: String? = nil) {
        if let index = plants.firstIndex(where: { $0.id == id }) {
            plants[index].lastPruned = Date()
            completePlannedOrCreateNew(plantIndex: index, type: .pruned, note: note, photoID: photoID)
            save()
        }
    }

    // MARK: - Fertilize a Plant
    func fertilize(id: UUID, note: String? = nil, photoID: String? = nil) {
        if let index = plants.firstIndex(where: { $0.id == id }) {
            plants[index].lastFertilized = Date()
            completePlannedOrCreateNew(plantIndex: index, type: .fertilized, note: note, photoID: photoID)
            save()
        }
    }

    // MARK: - Harvest a Plant
    func harvest(id: UUID, note: String? = nil, photoID: String? = nil) {
        if let index = plants.firstIndex(where: { $0.id == id }) {
            plants[index].lastHarvested = Date()
            completePlannedOrCreateNew(plantIndex: index, type: .harvested, note: note, photoID: photoID)
            save()
        }
    }

    // MARK: - Treat Pests
    func treatPests(id: UUID, note: String? = nil, photoID: String? = nil) {
        if let index = plants.firstIndex(where: { $0.id == id }) {
            plants[index].lastTreatedPests = Date()
            completePlannedOrCreateNew(plantIndex: index, type: .pestControl, note: note, photoID: photoID)
            save()
        }
    }

    // MARK: - Treat Diseases
    func treatDiseases(id: UUID, note: String? = nil, photoID: String? = nil) {
        if let index = plants.firstIndex(where: { $0.id == id }) {
            plants[index].lastTreatedDiseases = Date()
            completePlannedOrCreateNew(plantIndex: index, type: .diseaseControl, note: note, photoID: photoID)
            save()
        }
    }

    // MARK: - Planned → Done Transition
    // Checks if a "planned" activity of this type exists for the current month.
    // If yes: transitions it to "done" (fills in note, photo, who did it, completion date).
    // If no: creates a brand-new "done" activity (same as before for manual logging).
    //
    // This is the KEY method that makes the planned/done system work.
    // When Arborist auto-creates planned tasks at the start of the month,
    // and the user later marks them done, this method connects the two.
    private func completePlannedOrCreateNew(plantIndex: Int, type: CareType, note: String?, photoID: String?) {
        let calendar = Calendar.current
        let now = Date()

        // Look for an existing planned activity of this type in the current month
        if let actIdx = plants[plantIndex].activities.firstIndex(where: {
            $0.type == type && $0.status == .planned &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }) {
            // Found a planned activity — transition it to done
            plants[plantIndex].activities[actIdx].status = .done
            plants[plantIndex].activities[actIdx].completionDate = now
            plants[plantIndex].activities[actIdx].note = note
            plants[plantIndex].activities[actIdx].photoID = photoID
            plants[plantIndex].activities[actIdx].memberName = UserDefaults.standard.string(forKey: "userName")
        } else {
            // No planned activity found — create a new "done" activity
            let activity = CareActivity(
                type: type,
                date: now,
                note: note,
                photoID: photoID,
                memberName: UserDefaults.standard.string(forKey: "userName"),
                status: .done
            )
            plants[plantIndex].activities.append(activity)
        }
    }

    // MARK: - CareAction Engine: Auto-Plan Activities
    // Called on app launch. Reads TreeIntelligence for each plant and creates
    // "planned" activities for everything that's due this month.
    //
    // This is the core of the CareAction Engine — it turns static species
    // knowledge (TreeIntelligence) into actionable tasks for the user.
    //
    // Uses a UserDefaults key to avoid duplicate generation — only runs once per month.
    // If a planned or done activity already exists for a care type this month, skips it.
    func generatePlannedActivities() {
        let calendar = Calendar.current
        let now = Date()
        let yearMonth = "\(calendar.component(.year, from: now))-\(calendar.component(.month, from: now))"

        // Check if we already generated plans this month
        let lastPlanned = UserDefaults.standard.string(forKey: "lastAutoPlannedMonth") ?? ""
        if lastPlanned == yearMonth { return }

        var changed = false

        for index in plants.indices {
            guard let species = TreeEncyclopedia.find(name: plants[index].name) else { continue }
            let intel = species.intelligence

            // Each care type that TreeIntelligence says is due this month
            let careChecks: [(check: Bool, type: CareType)] = [
                (intel.shouldPruneThisMonth(), .pruned),
                (intel.shouldFertilizeThisMonth(), .fertilized),
                (intel.isHarvestTime(), .harvested),
                (intel.shouldTreatPestsThisMonth(), .pestControl),
                (intel.shouldTreatDiseasesThisMonth(), .diseaseControl),
            ]

            for (shouldDo, careType) in careChecks {
                guard shouldDo else { continue }

                // Don't create if a planned or done activity already exists this month
                let alreadyExists = plants[index].activities.contains { activity in
                    activity.type == careType &&
                    calendar.isDate(activity.date, equalTo: now, toGranularity: .month)
                }
                if !alreadyExists {
                    let planned = CareActivity(
                        type: careType,
                        date: now,
                        status: .planned
                    )
                    plants[index].activities.append(planned)
                    changed = true
                }
            }
        }

        UserDefaults.standard.set(yearMonth, forKey: "lastAutoPlannedMonth")
        if changed { save() }
    }

    // MARK: - Generate Plans for a Single Plant
    // Called when a new plant is added mid-month — generates planned activities
    // for just that plant, not all plants (since the others were already planned).
    func generatePlannedActivitiesForNewPlant(_ plant: Plant) {
        guard let index = plants.firstIndex(where: { $0.id == plant.id }),
              let species = TreeEncyclopedia.find(name: plant.name) else { return }

        let calendar = Calendar.current
        let now = Date()
        let intel = species.intelligence
        var changed = false

        let careChecks: [(check: Bool, type: CareType)] = [
            (intel.shouldPruneThisMonth(), .pruned),
            (intel.shouldFertilizeThisMonth(), .fertilized),
            (intel.isHarvestTime(), .harvested),
            (intel.shouldTreatPestsThisMonth(), .pestControl),
            (intel.shouldTreatDiseasesThisMonth(), .diseaseControl),
        ]

        for (shouldDo, careType) in careChecks {
            guard shouldDo else { continue }
            let alreadyExists = plants[index].activities.contains { activity in
                activity.type == careType &&
                calendar.isDate(activity.date, equalTo: now, toGranularity: .month)
            }
            if !alreadyExists {
                let planned = CareActivity(type: careType, date: now, status: .planned)
                plants[index].activities.append(planned)
                changed = true
            }
        }

        if changed { save() }
    }

    // MARK: - Reminder Helpers
    // Only schedules notifications if the user has turned them on in Settings.
    // @AppStorage values are in UserDefaults, so we check directly.

    private func scheduleReminderIfEnabled(for plant: Plant) {
        let remindersEnabled = UserDefaults.standard.bool(forKey: "remindersEnabled")
        if remindersEnabled {
            NotificationManager.shared.scheduleReminder(for: plant)
        }
    }

    // Schedule CareAction Engine notifications (prune/fertilize/harvest) if enabled
    private func scheduleCareActionsIfEnabled(for plant: Plant) {
        let careActionEngineEnabled = UserDefaults.standard.bool(forKey: "careActionEngineEnabled")
        if careActionEngineEnabled {
            NotificationManager.shared.scheduleCareActionAlerts(for: plant)
        }
    }

    // MARK: - Reschedule Everything
    // Called at app launch to make sure all notifications are up to date.
    // This catches cases where the app was closed and dates have changed.
    func rescheduleAllNotifications() {
        let remindersEnabled = UserDefaults.standard.bool(forKey: "remindersEnabled")
        let careActionEngineEnabled = UserDefaults.standard.bool(forKey: "careActionEngineEnabled")

        if remindersEnabled {
            NotificationManager.shared.scheduleAllReminders(for: plants)
        }
        if careActionEngineEnabled {
            NotificationManager.shared.scheduleAllCareActionAlerts(for: plants)
        }
    }

    // MARK: - Save to Disk
    // Converts plants to JSON and writes it to a file.
    // JSON looks like: [{"name": "Basil", "type": "Herb", ...}, ...]
    func save() {
        do {
            let data = try JSONEncoder().encode(plants)
            try data.write(to: Self.fileURL)
        } catch {
            print("❌ Failed to save plants: \(error)")
        }
    }

    // MARK: - Load from Disk
    // Reads the JSON file and converts it back to [Plant].
    // Returns nil if no file exists (first launch).
    private static func load() -> [Plant]? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Plant].self, from: data)
        } catch {
            print("❌ Failed to load plants: \(error)")
            return nil
        }
    }

    // MARK: - File Location
    // Where the JSON file is saved on your phone.
    // Documents directory = a safe, persistent folder that survives app updates.
    private static var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("myGarden_plants.json")
    }
}
