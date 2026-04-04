import Foundation

// MARK: - Tree Intelligence (Compatibility Layer)
// This struct is the "resolved" format that the rest of the app uses.
// It flattens species + variety data into one object so existing code
// (CareAction Engine, notifications, dashboard) keeps working.
//
// New code should use PlantSpecies.speciesInfo + VarietyInfo directly.
// This struct exists for backward compatibility with:
// - PlantStore.swift (planned activities, notifications)
// - PlantListView.swift (smart care section)
// - PlantDetailView.swift (care info)
// - TreeIntelligenceView.swift (full intelligence display)
// - CareActionDetailView.swift (action details)
// - NotificationManager.swift (scheduling alerts)
// - WeatherManager.swift (weather intelligence)
//
// How it works:
//   PlantSpecies.resolvedIntelligence(forVariety: "Шпанка")
//   → merges species-level + variety-level data into this flat struct

struct TreeIntelligence: Codable {

    // MARK: - Pruning
    let pruningMonths: [Int]
    let pruningTips: String

    // MARK: - Fertilizing
    let fertilizerMonths: [Int]
    let fertilizerType: String

    // MARK: - Watering by Age
    let youngWateringDays: Int
    let matureWateringDays: Int
    let establishedWateringDays: Int
    let yearsToMature: Int

    // MARK: - Harvest (fruit trees & berry bushes only)
    let harvestMonths: [Int]?
    let yearsToBearing: Int?

    // MARK: - Environment
    let idealSoilPH: String
    let sunExposure: String
    let frostHardiness: Int
    let matureHeight: String

    // MARK: - Seasonal Tips
    let springTip: String
    let summerTip: String
    let autumnTip: String
    let winterTip: String

    // MARK: - Common Problems
    let commonPests: [String]
    let commonDiseases: [String]

    // MARK: - Pest & Disease Treatments
    let pestTreatmentMonths: [Int]
    let pestTreatmentTip: String
    let diseaseTreatmentMonths: [Int]
    let diseaseTreatmentTip: String

    // MARK: - Computed Helpers

    func wateringDays(forAge age: Int?) -> Int {
        guard let age = age else { return youngWateringDays }
        if age < yearsToMature { return youngWateringDays }
        else if age < 7 { return matureWateringDays }
        else { return establishedWateringDays }
    }

    func currentSeasonTip() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:  return springTip
        case 6...8:  return summerTip
        case 9...11: return autumnTip
        default:     return winterTip
        }
    }

    func shouldPruneThisMonth() -> Bool {
        let month = Calendar.current.component(.month, from: Date())
        return pruningMonths.contains(month)
    }

    func shouldFertilizeThisMonth() -> Bool {
        let month = Calendar.current.component(.month, from: Date())
        return fertilizerMonths.contains(month)
    }

    func isHarvestTime() -> Bool {
        guard let months = harvestMonths else { return false }
        let month = Calendar.current.component(.month, from: Date())
        return months.contains(month)
    }

    func shouldTreatPestsThisMonth() -> Bool {
        let month = Calendar.current.component(.month, from: Date())
        return pestTreatmentMonths.contains(month)
    }

    func shouldTreatDiseasesThisMonth() -> Bool {
        let month = Calendar.current.component(.month, from: Date())
        return diseaseTreatmentMonths.contains(month)
    }

    static func monthNames(from months: [Int]) -> String {
        let formatter = DateFormatter()
        return months.map { formatter.monthSymbols[$0 - 1] }.joined(separator: ", ")
    }
}

// MARK: - The Full Encyclopedia
// Loads all species data from TreeEncyclopedia.json.
//
// To add a new species:
// 1. Open TreeEncyclopedia.json
// 2. Copy an existing species block
// 3. Fill in the fields for the new species
// 4. Build — that's it!
//
// The JSON is the SINGLE SOURCE OF TRUTH for all species data.

struct TreeEncyclopedia {

    // MARK: - Loaded Data
    // Cached species loaded from JSON at first access.

    static let all: [PlantSpecies] = {
        guard let url = Bundle.main.url(forResource: "TreeEncyclopedia", withExtension: "json") else {
            print("⚠️ TreeEncyclopedia.json not found in bundle!")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode([PlantSpecies].self, from: data)
        } catch {
            print("⚠️ Failed to decode TreeEncyclopedia.json: \(error)")
            return []
        }
    }()

    // MARK: - Convenience: By Type

    static let forestTrees: [PlantSpecies] = all.filter { $0.type == .forestTree }
    static let fruitTrees: [PlantSpecies] = all.filter { $0.type == .fruitTree }
    static let bushes: [PlantSpecies] = all.filter { $0.type == .bush }

    static func species(for type: PlantType) -> [PlantSpecies] {
        switch type {
        case .forestTree: return forestTrees
        case .fruitTree:  return fruitTrees
        case .bush:       return bushes
        }
    }

    // MARK: - Convenience: Find Species

    static func find(name: String) -> PlantSpecies? {
        all.first { $0.name == name }
    }

    // MARK: - Convenience: Resolve Intelligence
    // Shortcut to get a resolved TreeIntelligence for a plant by name + variety.
    // Used throughout the app when you need the flat compatibility format.
    //
    // Example:
    //   TreeEncyclopedia.intelligence(for: "Cherry", variety: "Шпанка")
    //   → TreeIntelligence with merged species + variety data

    static func intelligence(for speciesName: String, variety: String? = nil) -> TreeIntelligence? {
        guard let species = find(name: speciesName) else { return nil }
        return species.resolvedIntelligence(forVariety: variety)
    }
}
