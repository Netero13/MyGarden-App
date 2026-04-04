import Foundation

// MARK: - Encyclopedia Models
// These structs define the TWO-LEVEL data structure for the Tree Encyclopedia:
//
// SPECIES LEVEL (what's true for ALL varieties):
//   → soil, sun, fertilizing, pests, diseases, seasonal tips
//
// VARIETY LEVEL (what's specific to each variety):
//   → frost hardiness, height, watering, pruning, harvest, fruit,
//     pollination, yield, disease resistance, strengths/weaknesses
//
// The JSON file (TreeEncyclopedia.json) follows this exact structure.
// To add a new species: copy a JSON block, fill in the fields.

// MARK: - Species-Level Info
// Universal facts about a species — applies to every variety.

struct SpeciesInfo: Codable {
    let soilPH: String                    // e.g. "6.0-7.0"
    let sun: String                       // "Full sun", "Partial shade", etc.
    let fertilizing: FertilizingInfo      // when + what to fertilize
    let pests: PestInfo                   // common pests + treatment
    let diseases: DiseaseInfo             // common diseases + treatment
    let seasonalTips: SeasonalTips        // spring/summer/autumn/winter advice
}

// MARK: - Variety-Level Info
// What makes one variety different from another.

struct VarietyInfo: Identifiable, Codable {
    var id: String { name }

    let name: String                      // e.g. "Шпанка"
    let photo: String?                    // image filename (future use)
    let ukrainianRegion: String           // where it grows best
    let frostHardiness: Int               // minimum survival temp °C
    let matureHeight: String              // e.g. "5-6m"

    // Care that can differ per variety
    let watering: WateringInfo            // age-based watering schedule
    let pruning: PruningInfo              // when + how to prune

    // Harvest (nil for forest/decorative trees)
    let harvest: HarvestInfo?
    let pollination: String?              // "Self-fertile", "Needs partner", etc.

    // Fruit characteristics (nil for non-fruiting)
    let fruit: FruitInfo?
    let yield: String?                    // e.g. "High (up to 40 kg/tree)"

    // Resilience
    let diseaseResistance: String?        // e.g. "Moderate coccomycosis resistance"
    let strengths: [String]               // what this variety does well
    let weaknesses: [String]              // known downsides

    // Free-text notes
    let notes: String                     // extra info, cultural significance, etc.
}

// MARK: - Sub-Models

struct FertilizingInfo: Codable {
    let months: [Int]                     // which months (1-12)
    let type: String                      // what to apply
}

struct PestInfo: Codable {
    let common: [String]                  // list of common pests
    let treatmentMonths: [Int]            // when to treat
    let treatmentTip: String              // how to treat
}

struct DiseaseInfo: Codable {
    let common: [String]                  // list of common diseases
    let treatmentMonths: [Int]            // when to treat
    let treatmentTip: String              // how to treat
}

struct SeasonalTips: Codable {
    let spring: String
    let summer: String
    let autumn: String
    let winter: String

    // Convenience: get tip for current month
    func currentTip() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:  return spring
        case 6...8:  return summer
        case 9...11: return autumn
        default:     return winter
        }
    }
}

struct WateringInfo: Codable {
    let youngDays: Int                    // years 0-3: water every X days
    let matureDays: Int                   // years 3+: water every X days
    let establishedDays: Int              // years 7+: water every X days
    let yearsToMature: Int                // when to switch young → mature

    // Returns recommended watering frequency for a given tree age
    func daysForAge(_ age: Int?) -> Int {
        guard let age = age else { return youngDays }
        if age < yearsToMature { return youngDays }
        else if age < 7 { return matureDays }
        else { return establishedDays }
    }
}

struct PruningInfo: Codable {
    let months: [Int]                     // which months (1-12)
    let tips: String                      // how to prune this variety
}

struct HarvestInfo: Codable {
    let months: [Int]                     // when to harvest (1-12)
    let yearsToBearing: Int               // years until first harvest
    let period: String                    // "early", "mid", "late"
}

struct FruitInfo: Codable {
    let color: String                     // e.g. "Dark red"
    let size: String                      // e.g. "6-7g"
    let taste: String                     // e.g. "Sweet-sour, excellent fresh"
}

// MARK: - Plant Species (top-level encyclopedia entry)
// One entry per species (e.g. "Cherry"). Contains species-wide info
// plus an array of varieties with variety-specific data.

struct PlantSpecies: Identifiable, Codable {
    var id: String { name }

    let name: String                      // English name, e.g. "Cherry"
    let ukrainianName: String             // Ukrainian name, e.g. "Вишня"
    let type: PlantType                   // .fruitTree, .forestTree, .bush
    let speciesInfo: SpeciesInfo          // universal facts
    let varieties: [VarietyInfo]          // variety-specific data

    // MARK: - Convenience: Find Variety
    func variety(named: String?) -> VarietyInfo? {
        guard let named = named else { return nil }
        return varieties.first { $0.name == named }
    }

    // MARK: - Convenience: Default Watering Days
    // Uses the first variety's young watering as the species default.
    var defaultWateringDays: Int {
        varieties.first?.watering.youngDays ?? 7
    }

    // MARK: - Compatibility: Build TreeIntelligence
    // Creates a "resolved" TreeIntelligence from species + variety data.
    // This lets existing code (CareAction Engine, notifications, dashboard)
    // keep working without rewriting everything at once.
    //
    // Pass the user's variety name to get variety-specific data.
    // Falls back to first variety if no match.
    func resolvedIntelligence(forVariety varietyName: String? = nil) -> TreeIntelligence {
        let v = variety(named: varietyName) ?? varieties.first!

        return TreeIntelligence(
            pruningMonths: v.pruning.months,
            pruningTips: v.pruning.tips,
            fertilizerMonths: speciesInfo.fertilizing.months,
            fertilizerType: speciesInfo.fertilizing.type,
            youngWateringDays: v.watering.youngDays,
            matureWateringDays: v.watering.matureDays,
            establishedWateringDays: v.watering.establishedDays,
            yearsToMature: v.watering.yearsToMature,
            harvestMonths: v.harvest?.months,
            yearsToBearing: v.harvest?.yearsToBearing,
            idealSoilPH: speciesInfo.soilPH,
            sunExposure: speciesInfo.sun,
            frostHardiness: v.frostHardiness,
            matureHeight: v.matureHeight,
            springTip: speciesInfo.seasonalTips.spring,
            summerTip: speciesInfo.seasonalTips.summer,
            autumnTip: speciesInfo.seasonalTips.autumn,
            winterTip: speciesInfo.seasonalTips.winter,
            commonPests: speciesInfo.pests.common,
            commonDiseases: speciesInfo.diseases.common,
            pestTreatmentMonths: speciesInfo.pests.treatmentMonths,
            pestTreatmentTip: speciesInfo.pests.treatmentTip,
            diseaseTreatmentMonths: speciesInfo.diseases.treatmentMonths,
            diseaseTreatmentTip: speciesInfo.diseases.treatmentTip
        )
    }
}
