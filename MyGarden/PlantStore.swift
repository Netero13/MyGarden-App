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
    }

    // MARK: - Delete a Plant
    // 'IndexSet' is what SwiftUI gives us when the user swipes to delete.
    // It tells us WHICH items (by position) to remove.
    func delete(at offsets: IndexSet) {
        // Cancel reminders for deleted plants
        for offset in offsets {
            NotificationManager.shared.cancelReminder(for: plants[offset].id)
        }
        plants.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Delete by ID
    // Sometimes we know the plant's ID but not its position.
    func delete(id: UUID) {
        NotificationManager.shared.cancelReminder(for: id)
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
        }
    }

    // MARK: - Water a Plant
    func water(id: UUID) {
        if let index = plants.firstIndex(where: { $0.id == id }) {
            plants[index].lastWatered = Date()
            save()
            scheduleReminderIfEnabled(for: plants[index])
        }
    }

    // MARK: - Reminder Helper
    // Only schedules a reminder if the user has turned on reminders in settings.
    // @AppStorage values are in UserDefaults, so we check directly.
    private func scheduleReminderIfEnabled(for plant: Plant) {
        let remindersEnabled = UserDefaults.standard.bool(forKey: "remindersEnabled")
        if remindersEnabled {
            NotificationManager.shared.scheduleReminder(for: plant)
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
