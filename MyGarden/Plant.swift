import Foundation
import SwiftUI

// MARK: - Plant Model
// This is the "blueprint" for what a Tree or Bush is in Arborist.
// Every plant will have these properties.

struct Plant: Identifiable, Codable {

    // 'id' gives each plant a unique identity so SwiftUI can tell them apart in a list.
    var id = UUID()

    // Basic info
    var name: String              // e.g. "Cherry", "Oak", "Raspberry"
    var type: PlantType           // forestTree, fruitTree, or bush
    var variety: String?          // optional, e.g. "Шпанка", "Антонівка"
    var photoID: String?          // ID of the plant's profile photo (stored as a file)

    // Age tracking — when was this tree/bush planted?
    // Used to calculate age and adjust care recommendations.
    // nil = unknown planting date.
    var plantingYear: Int?

    // Watering
    var wateringFrequencyDays: Int // how often to water (in days)
    var lastWatered: Date?         // when you last watered it (nil = never watered yet)

    // Garden Map position — where this plant sits on the visual garden map.
    // nil means the plant hasn't been placed on the map yet.
    var gardenX: Double?
    var gardenY: Double?

    // Tracking
    var dateAdded: Date            // when you added this plant to your garden

    // Activity Journal — a log of everything you've done to this plant.
    var activities: [CareActivity] = []

    // MARK: - Computed: Age
    // Calculates how old the tree/bush is from planting year.
    // Returns nil if planting year is unknown.
    var age: Int? {
        guard let year = plantingYear else { return nil }
        return Calendar.current.component(.year, from: Date()) - year
    }

    // MARK: - Computed: Age Label
    // A friendly string like "3 years old" or "Newly planted"
    var ageLabel: String? {
        guard let age = age else { return nil }
        if age == 0 { return "Newly planted" }
        if age == 1 { return "1 year old" }
        return "\(age) years old"
    }

    // MARK: - Computed: Next Watering Date
    var nextWateringDate: Date? {
        guard let lastWatered = lastWatered else { return nil }
        return Calendar.current.date(byAdding: .day, value: wateringFrequencyDays, to: lastWatered)
    }

    // MARK: - Computed: Needs Watering
    var needsWatering: Bool {
        guard let nextDate = nextWateringDate else { return true }
        return nextDate <= Date()
    }

    // MARK: - Display Name
    // Shows variety if available, e.g. "Cherry (Шпанка)"
    var displayName: String {
        if let variety = variety {
            return "\(name) (\(variety))"
        }
        return name
    }
}

// MARK: - Plant Type
// Arborist focuses on THREE categories: forest trees, fruit trees, and bushes.
// Each type has its own icon, color, and display name.

enum PlantType: String, Codable, CaseIterable {
    case fruitTree = "Fruit Tree"
    case forestTree = "Forest Tree"
    case bush = "Bush"

    // Localized display name
    var localizedName: String {
        NSLocalizedString(rawValue, comment: "")
    }

    // Each type gets its own icon (using Apple's built-in SF Symbols)
    var icon: String {
        switch self {
        case .forestTree: return "tree.fill"
        case .fruitTree:  return "tree.circle.fill"
        case .bush:       return "laurel.leading"
        }
    }

    // Each type gets a color
    var color: Color {
        switch self {
        case .forestTree: return .brown
        case .fruitTree:  return .red
        case .bush:       return .purple
        }
    }
}

// MARK: - Sample Data
// Ukrainian trees and bushes for testing & previews.

extension Plant {
    static let samples: [Plant] = [

        // -- Forest Trees --
        Plant(
            name: "Oak",
            type: .forestTree,
            variety: "Дуб звичайний",
            plantingYear: 2020,
            wateringFrequencyDays: 7,
            lastWatered: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Birch",
            type: .forestTree,
            variety: "Береза повисла",
            plantingYear: 2022,
            wateringFrequencyDays: 5,
            lastWatered: Date(),
            dateAdded: Date()
        ),
        Plant(
            name: "Maple",
            type: .forestTree,
            variety: "Клен гостролистий",
            plantingYear: 2019,
            wateringFrequencyDays: 7,
            lastWatered: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            dateAdded: Date()
        ),

        // -- Fruit Trees --
        Plant(
            name: "Cherry",
            type: .fruitTree,
            variety: "Шпанка",
            plantingYear: 2021,
            wateringFrequencyDays: 7,
            lastWatered: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Apple",
            type: .fruitTree,
            variety: "Антонівка",
            plantingYear: 2018,
            wateringFrequencyDays: 7,
            lastWatered: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Pear",
            type: .fruitTree,
            variety: "Вільямс",
            plantingYear: 2023,
            wateringFrequencyDays: 7,
            lastWatered: Date(),
            dateAdded: Date()
        ),

        // -- Bushes --
        Plant(
            name: "Currant",
            type: .bush,
            variety: "Смородина чорна",
            plantingYear: 2022,
            wateringFrequencyDays: 5,
            lastWatered: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Raspberry",
            type: .bush,
            variety: "Малина ремонтантна",
            plantingYear: 2023,
            wateringFrequencyDays: 4,
            lastWatered: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
            dateAdded: Date()
        ),
    ]
}
