import Foundation
import SwiftUI

// MARK: - Plant Model
// This is the "blueprint" for what a Plant is in our app.
// Every plant will have these properties.

struct Plant: Identifiable, Codable {

    // 'id' gives each plant a unique identity so SwiftUI can tell them apart in a list.
    var id = UUID()

    // Basic info
    var name: String              // e.g. "Basil", "Tomato"
    var type: PlantType           // herb, vegetable, flower, or succulent

    // Watering
    var wateringFrequencyDays: Int // how often to water (in days)
    var lastWatered: Date?         // when you last watered it (nil = never watered yet)

    // Tracking
    var dateAdded: Date            // when you added this plant to your garden

    // MARK: - Computed Property
    // This figures out the NEXT watering date automatically.
    // You don't set this — the app calculates it from lastWatered + frequency.
    var nextWateringDate: Date? {
        guard let lastWatered = lastWatered else { return nil }
        return Calendar.current.date(byAdding: .day, value: wateringFrequencyDays, to: lastWatered)
    }

    // MARK: - Convenience Check
    // Returns true if the plant needs watering today (or is overdue).
    var needsWatering: Bool {
        guard let nextDate = nextWateringDate else { return true }
        return nextDate <= Date()
    }
}

// MARK: - Plant Type
// An 'enum' is like a multiple-choice list — a plant can ONLY be one of these types.

enum PlantType: String, Codable, CaseIterable {
    case herb = "Herb"
    case vegetable = "Vegetable"
    case flower = "Flower"
    case succulent = "Succulent"

    // Each type gets its own icon (using Apple's built-in SF Symbols)
    var icon: String {
        switch self {
        case .herb:       return "leaf.fill"
        case .vegetable:  return "carrot.fill"
        case .flower:     return "camera.macro"
        case .succulent:  return "drop.fill"
        }
    }

    // Each type gets a color
    var color: Color {
        switch self {
        case .herb:       return .green
        case .vegetable:  return .orange
        case .flower:     return .pink
        case .succulent:  return .mint
        }
    }
}

// MARK: - Sample Data
// Fake plants for testing. We'll use these to preview our screens before real data exists.

extension Plant {
    static let samples: [Plant] = [
        Plant(
            name: "Basil",
            type: .herb,
            wateringFrequencyDays: 2,
            lastWatered: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Tomato",
            type: .vegetable,
            wateringFrequencyDays: 3,
            lastWatered: Calendar.current.date(byAdding: .day, value: -4, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Sunflower",
            type: .flower,
            wateringFrequencyDays: 5,
            lastWatered: Date(),
            dateAdded: Date()
        ),
        Plant(
            name: "Aloe Vera",
            type: .succulent,
            wateringFrequencyDays: 10,
            lastWatered: nil,
            dateAdded: Date()
        ),
    ]
}
