import Foundation
import SwiftUI

// MARK: - Plant Model
// This is the "blueprint" for what a Plant is in our app.
// Every plant will have these properties.

struct Plant: Identifiable, Codable {

    // 'id' gives each plant a unique identity so SwiftUI can tell them apart in a list.
    var id = UUID()

    // Basic info
    var name: String              // e.g. "Basil", "Oak", "Cherry"
    var type: PlantType           // herb, vegetable, flower, succulent, forestTree, fruitTree
    var variety: String?          // optional extra detail, e.g. "Red Oak", "Antonivka Apple"

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

    // MARK: - Display Name
    // Shows variety if available, e.g. "Cherry (Shpanka)" instead of just "Cherry"
    var displayName: String {
        if let variety = variety {
            return "\(name) (\(variety))"
        }
        return name
    }
}

// MARK: - Plant Type
// An 'enum' is like a multiple-choice list — a plant can ONLY be one of these types.
// We added forestTree and fruitTree for Ukrainian trees!

enum PlantType: String, Codable, CaseIterable {
    case herb = "Herb"
    case vegetable = "Vegetable"
    case flower = "Flower"
    case succulent = "Succulent"
    case forestTree = "Forest Tree"
    case fruitTree = "Fruit Tree"
    case bush = "Bush"

    // Each type gets its own icon (using Apple's built-in SF Symbols)
    var icon: String {
        switch self {
        case .herb:       return "leaf.fill"
        case .vegetable:  return "carrot.fill"
        case .flower:     return "camera.macro"
        case .succulent:  return "drop.fill"
        case .forestTree: return "tree.fill"
        case .fruitTree:  return "tree.circle.fill"
        case .bush:       return "laurel.leading"
        }
    }

    // Each type gets a color
    var color: Color {
        switch self {
        case .herb:       return .green
        case .vegetable:  return .orange
        case .flower:     return .pink
        case .succulent:  return .mint
        case .forestTree: return .brown
        case .fruitTree:  return .red
        case .bush:       return .purple
        }
    }
}

// MARK: - Sample Data
// Fake plants for testing. Includes Ukrainian trees and bushes!
// 🇺🇦 Forest trees: Дуб, Береза, Сосна, Бук, Липа, Клен, Ялина
// 🇺🇦 Fruit trees: Вишня, Яблуня, Груша, Слива, Абрикос, Горіх, Персик, Черешня
// 🇺🇦 Bushes: Смородина, Малина, Полуниця, Лохина

extension Plant {
    static let samples: [Plant] = [

        // -- Herbs & Vegetables --
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

        // -- Ukrainian Forest Trees --
        // These are common across Ukraine's forests — from Carpathians to Polissia
        Plant(
            name: "Oak",
            type: .forestTree,
            variety: "Дуб звичайний",
            wateringFrequencyDays: 14,
            lastWatered: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Birch",
            type: .forestTree,
            variety: "Береза повисла",
            wateringFrequencyDays: 10,
            lastWatered: Date(),
            dateAdded: Date()
        ),
        Plant(
            name: "Pine",
            type: .forestTree,
            variety: "Сосна звичайна",
            wateringFrequencyDays: 14,
            lastWatered: nil,
            dateAdded: Date()
        ),
        Plant(
            name: "Linden",
            type: .forestTree,
            variety: "Липа серцелиста",
            wateringFrequencyDays: 12,
            lastWatered: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Beech",
            type: .forestTree,
            variety: "Бук лісовий",
            wateringFrequencyDays: 14,
            lastWatered: Date(),
            dateAdded: Date()
        ),
        Plant(
            name: "Maple",
            type: .forestTree,
            variety: "Клен гостролистий",
            wateringFrequencyDays: 12,
            lastWatered: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Spruce",
            type: .forestTree,
            variety: "Ялина європейська",
            wateringFrequencyDays: 14,
            lastWatered: nil,
            dateAdded: Date()
        ),

        // -- Ukrainian Fruit Trees --
        // Popular fruit trees grown in Ukrainian gardens and orchards
        Plant(
            name: "Cherry",
            type: .fruitTree,
            variety: "Шпанка",
            wateringFrequencyDays: 7,
            lastWatered: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Apple",
            type: .fruitTree,
            variety: "Антонівка",
            wateringFrequencyDays: 7,
            lastWatered: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Pear",
            type: .fruitTree,
            variety: "Вільямс",
            wateringFrequencyDays: 7,
            lastWatered: Date(),
            dateAdded: Date()
        ),
        Plant(
            name: "Plum",
            type: .fruitTree,
            variety: "Угорка",
            wateringFrequencyDays: 7,
            lastWatered: Calendar.current.date(byAdding: .day, value: -6, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Apricot",
            type: .fruitTree,
            variety: "Краснощокий",
            wateringFrequencyDays: 10,
            lastWatered: nil,
            dateAdded: Date()
        ),
        Plant(
            name: "Walnut",
            type: .fruitTree,
            variety: "Горіх волоський",
            wateringFrequencyDays: 14,
            lastWatered: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Peach",
            type: .fruitTree,
            variety: "Персик київський",
            wateringFrequencyDays: 7,
            lastWatered: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Merry Cherry",
            type: .fruitTree,
            variety: "Черешня великоплідна",
            wateringFrequencyDays: 7,
            lastWatered: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
            dateAdded: Date()
        ),

        // -- Ukrainian Berry Bushes --
        // Common bushes grown in Ukrainian gardens (кущі)
        Plant(
            name: "Currant",
            type: .bush,
            variety: "Смородина чорна",
            wateringFrequencyDays: 5,
            lastWatered: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Raspberry",
            type: .bush,
            variety: "Малина ремонтантна",
            wateringFrequencyDays: 4,
            lastWatered: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Strawberry",
            type: .bush,
            variety: "Полуниця Вікторія",
            wateringFrequencyDays: 3,
            lastWatered: Date(),
            dateAdded: Date()
        ),
        Plant(
            name: "Blueberry",
            type: .bush,
            variety: "Лохина високоросла",
            wateringFrequencyDays: 4,
            lastWatered: nil,
            dateAdded: Date()
        ),
    ]
}
