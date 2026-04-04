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

    // Age tracking — two separate dates:
    // birthYear = when the tree was actually born (seedling/sapling age)
    //             THIS IS REQUIRED — the app uses it for all age-based care.
    // plantingYear = when this tree was planted IN YOUR GARDEN (optional, informational)
    //
    // Example: You buy a 3-year-old cherry sapling in 2026.
    //   birthYear = 2023 (actual tree age — REQUIRED)
    //   plantingYear = 2026 (when you planted it — optional)
    var birthYear: Int
    var plantingYear: Int?

    // Watering
    var wateringFrequencyDays: Int // how often to water (in days)
    var lastWatered: Date?         // when you last watered it (nil = never watered yet)

    // Care tracking — when each care type was last performed.
    // These let the app know "you already pruned this month" so it removes
    // the task from the dashboard. Same pattern as lastWatered.
    var lastPruned: Date?
    var lastFertilized: Date?
    var lastHarvested: Date?
    var lastTreatedPests: Date?
    var lastTreatedDiseases: Date?

    // Garden Map position — where this plant sits on the visual garden map.
    // nil means the plant hasn't been placed on the map yet.
    var gardenX: Double?
    var gardenY: Double?

    // Tracking
    var dateAdded: Date            // when you added this plant to your garden

    // Activity Journal — a log of everything you've done to this plant.
    var activities: [CareActivity] = []

    // MARK: - Computed: Age
    // Calculates how old the tree/bush is from birthYear.
    // Always available because birthYear is required.
    var age: Int {
        return Calendar.current.component(.year, from: Date()) - birthYear
    }

    // MARK: - Computed: Age Label
    // A friendly localized string like "3 years old" or "Newly planted"
    var ageLabel: String {
        if age == 0 { return NSLocalizedString("Newly planted", comment: "") }
        return String(format: NSLocalizedString("About %lld year(s) old", comment: ""), age)
    }

    // MARK: - Memberwise Init
    // Needed because we provide a custom Codable init below.
    init(
        id: UUID = UUID(),
        name: String,
        type: PlantType,
        variety: String? = nil,
        photoID: String? = nil,
        birthYear: Int,
        plantingYear: Int? = nil,
        wateringFrequencyDays: Int,
        lastWatered: Date? = nil,
        lastPruned: Date? = nil,
        lastFertilized: Date? = nil,
        lastHarvested: Date? = nil,
        lastTreatedPests: Date? = nil,
        lastTreatedDiseases: Date? = nil,
        gardenX: Double? = nil,
        gardenY: Double? = nil,
        dateAdded: Date,
        activities: [CareActivity] = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.variety = variety
        self.photoID = photoID
        self.birthYear = birthYear
        self.plantingYear = plantingYear
        self.wateringFrequencyDays = wateringFrequencyDays
        self.lastWatered = lastWatered
        self.lastPruned = lastPruned
        self.lastFertilized = lastFertilized
        self.lastHarvested = lastHarvested
        self.lastTreatedPests = lastTreatedPests
        self.lastTreatedDiseases = lastTreatedDiseases
        self.gardenX = gardenX
        self.gardenY = gardenY
        self.dateAdded = dateAdded
        self.activities = activities
    }

    // Backward compatibility: old JSON may have birthYear as nil.
    // If missing, we fall back to plantingYear, then default to current year.
    enum CodingKeys: String, CodingKey {
        case id, name, type, variety, photoID
        case birthYear, plantingYear
        case wateringFrequencyDays, lastWatered
        case lastPruned, lastFertilized, lastHarvested
        case lastTreatedPests, lastTreatedDiseases
        case gardenX, gardenY, dateAdded, activities
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        type = try c.decode(PlantType.self, forKey: .type)
        variety = try c.decodeIfPresent(String.self, forKey: .variety)
        photoID = try c.decodeIfPresent(String.self, forKey: .photoID)
        plantingYear = try c.decodeIfPresent(Int.self, forKey: .plantingYear)
        // Backward compat: old data might not have birthYear
        if let by = try c.decodeIfPresent(Int.self, forKey: .birthYear) {
            birthYear = by
        } else if let py = plantingYear {
            birthYear = py  // fallback to planting year
        } else {
            birthYear = Calendar.current.component(.year, from: Date())
        }
        wateringFrequencyDays = try c.decode(Int.self, forKey: .wateringFrequencyDays)
        lastWatered = try c.decodeIfPresent(Date.self, forKey: .lastWatered)
        // Care tracking — backward compat: old JSON won't have these, so nil is fine
        lastPruned = try c.decodeIfPresent(Date.self, forKey: .lastPruned)
        lastFertilized = try c.decodeIfPresent(Date.self, forKey: .lastFertilized)
        lastHarvested = try c.decodeIfPresent(Date.self, forKey: .lastHarvested)
        lastTreatedPests = try c.decodeIfPresent(Date.self, forKey: .lastTreatedPests)
        lastTreatedDiseases = try c.decodeIfPresent(Date.self, forKey: .lastTreatedDiseases)
        gardenX = try c.decodeIfPresent(Double.self, forKey: .gardenX)
        gardenY = try c.decodeIfPresent(Double.self, forKey: .gardenY)
        dateAdded = try c.decode(Date.self, forKey: .dateAdded)
        activities = try c.decodeIfPresent([CareActivity].self, forKey: .activities) ?? []
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

    // MARK: - Was Care Done This Month?
    // Checks if a specific care type was already performed this month.
    // Used by the dashboard to hide tasks you've already completed.
    // Example: wasDoneThisMonth(.pruned) → true if lastPruned is in April 2026
    func wasDoneThisMonth(_ type: CareType) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let date: Date?
        switch type {
        case .pruned:         date = lastPruned
        case .fertilized:     date = lastFertilized
        case .harvested:      date = lastHarvested
        case .pestControl:    date = lastTreatedPests
        case .diseaseControl: date = lastTreatedDiseases
        case .watered:        date = lastWatered
        default:              return false
        }
        guard let d = date else { return false }
        return calendar.isDate(d, equalTo: now, toGranularity: .month)
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
            birthYear: 2018,
            plantingYear: 2020,
            wateringFrequencyDays: 7,
            lastWatered: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Birch",
            type: .forestTree,
            variety: "Береза повисла",
            birthYear: 2021,
            plantingYear: 2022,
            wateringFrequencyDays: 5,
            lastWatered: Date(),
            dateAdded: Date()
        ),
        Plant(
            name: "Maple",
            type: .forestTree,
            variety: "Клен гостролистий",
            birthYear: 2016,
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
            birthYear: 2019,
            plantingYear: 2021,
            wateringFrequencyDays: 7,
            lastWatered: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Apple",
            type: .fruitTree,
            variety: "Антонівка",
            birthYear: 2015,
            plantingYear: 2018,
            wateringFrequencyDays: 7,
            lastWatered: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Pear",
            type: .fruitTree,
            variety: "Вільямс",
            birthYear: 2022,
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
            birthYear: 2021,
            plantingYear: 2022,
            wateringFrequencyDays: 5,
            lastWatered: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            dateAdded: Date()
        ),
        Plant(
            name: "Raspberry",
            type: .bush,
            variety: "Малина ремонтантна",
            birthYear: 2022,
            plantingYear: 2023,
            wateringFrequencyDays: 4,
            lastWatered: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
            dateAdded: Date()
        ),
    ]
}
