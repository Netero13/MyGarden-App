import Foundation

// MARK: - Care Intelligence
// The "brain" of Arborist — detailed care data for each tree/bush species.
// This tells the user WHEN to do WHAT and WHY.
//
// All data is based on Ukrainian continental climate:
// - Climate zone: mostly 5b-7a (USDA)
// - Active season: April-October
// - Winters: -15°C to -25°C depending on region
// - Soil: typically chernozem (black earth), pH 6.0-7.0
//
// Age-based care is critical: a 1-year-old cherry needs MUCH more
// water than a 10-year-old one. Arborist adjusts automatically.

struct CareIntelligence: Codable {

    // MARK: - Pruning
    let pruningMonths: [Int]           // which months to prune (1-12)
    let pruningTips: String            // how to prune this species

    // MARK: - Fertilizing
    let fertilizerMonths: [Int]        // which months to fertilize
    let fertilizerType: String         // what type of fertilizer to use

    // MARK: - Watering by Age
    // Young trees need MUCH more water than established ones.
    // These values define watering frequency for different life stages.
    let youngWateringDays: Int         // years 0-3: water every X days
    let matureWateringDays: Int        // years 3+: water every X days
    let establishedWateringDays: Int   // years 7+: water every X days
    let yearsToMature: Int             // when to switch from young to mature

    // MARK: - Harvest (fruit trees & berry bushes only)
    let harvestMonths: [Int]?          // when to pick fruit (nil = no fruit)
    let yearsToBearing: Int?           // years until first fruit/berry harvest

    // MARK: - Environment
    let idealSoilPH: String            // e.g. "6.0-7.0"
    let sunExposure: String            // "Full sun", "Partial shade", etc.
    let frostHardiness: Int            // minimum survival temp in °C
    let matureHeight: String           // expected adult height, e.g. "15-20m"

    // MARK: - Seasonal Tips
    // Specific advice for each season, tailored to Ukrainian climate.
    let springTip: String
    let summerTip: String
    let autumnTip: String
    let winterTip: String

    // MARK: - Common Problems
    let commonPests: [String]          // pests to watch for
    let commonDiseases: [String]       // diseases to watch for

    // MARK: - Computed: Watering for Age
    // Returns the recommended watering frequency based on tree age.
    func wateringDays(forAge age: Int?) -> Int {
        guard let age = age else { return youngWateringDays }
        if age < yearsToMature {
            return youngWateringDays
        } else if age < 7 {
            return matureWateringDays
        } else {
            return establishedWateringDays
        }
    }

    // MARK: - Computed: Current Season Tip
    func currentSeasonTip() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:  return springTip
        case 6...8:  return summerTip
        case 9...11: return autumnTip
        default:     return winterTip
        }
    }

    // MARK: - Computed: Should Prune Now?
    func shouldPruneThisMonth() -> Bool {
        let month = Calendar.current.component(.month, from: Date())
        return pruningMonths.contains(month)
    }

    // MARK: - Computed: Should Fertilize Now?
    func shouldFertilizeThisMonth() -> Bool {
        let month = Calendar.current.component(.month, from: Date())
        return fertilizerMonths.contains(month)
    }

    // MARK: - Computed: Is Harvest Time?
    func isHarvestTime() -> Bool {
        guard let months = harvestMonths else { return false }
        let month = Calendar.current.component(.month, from: Date())
        return months.contains(month)
    }

    // MARK: - Month Names Helper
    static func monthNames(from months: [Int]) -> String {
        let formatter = DateFormatter()
        return months.map { formatter.monthSymbols[$0 - 1] }.joined(separator: ", ")
    }
}

// MARK: - Plant Species
// Each species in the catalog with its care intelligence.

struct PlantSpecies: Identifiable, Codable {
    var id = UUID()
    var name: String              // e.g. "Cherry"
    var ukrainianName: String     // e.g. "Вишня"
    var type: PlantType           // .fruitTree, .forestTree, or .bush
    var defaultWateringDays: Int  // default watering frequency
    var varieties: [String]       // list of varieties to choose from
    var intelligence: CareIntelligence  // the smart care data
}

// MARK: - The Full Catalog
// All trees and bushes the user can choose from.
// Each species includes DEEP care intelligence for Ukrainian climate.

struct PlantCatalog {

    // MARK: - Forest Trees (Лісові / Декоративні дерева)
    // Watering data is for YOUNG / newly planted trees (first 2-3 years).
    // Established forest trees rarely need manual watering.

    static let forestTrees: [PlantSpecies] = [
        PlantSpecies(
            name: "Oak", ukrainianName: "Дуб", type: .forestTree,
            defaultWateringDays: 7,
            varieties: ["Звичайний", "Червоний", "Скельний", "Болотний"],
            intelligence: CareIntelligence(
                pruningMonths: [2, 3, 11],
                pruningTips: "Remove dead and crossing branches in late winter. Shape young trees to a central leader. Mature oaks rarely need pruning — only remove damaged limbs.",
                fertilizerMonths: [4, 5],
                fertilizerType: "Compost or balanced fertilizer (NPK 10-10-10) around the drip line. Oaks prefer organic matter — mulch with leaf compost.",
                youngWateringDays: 5,
                matureWateringDays: 10,
                establishedWateringDays: 21,
                yearsToMature: 4,
                harvestMonths: nil,
                yearsToBearing: nil,
                idealSoilPH: "5.5-7.0",
                sunExposure: "Full sun",
                frostHardiness: -30,
                matureHeight: "20-30m",
                springTip: "Apply mulch around the base. Inspect for oak leaf roller moths. Begin watering young trees as soil thaws.",
                summerTip: "Water deeply during dry spells. Watch for powdery mildew in humid weather. Young oaks benefit from afternoon shade.",
                autumnTip: "Don't remove fallen leaves — they're natural mulch. Apply final fertilizer in early October.",
                winterTip: "Oaks are very hardy. Wrap young tree trunks to prevent frost cracks and sunscald.",
                commonPests: ["Oak leaf roller", "Gypsy moth", "Oak bark beetle"],
                commonDiseases: ["Powdery mildew", "Oak wilt", "Root rot"]
            )
        ),
        PlantSpecies(
            name: "Birch", ukrainianName: "Береза", type: .forestTree,
            defaultWateringDays: 5,
            varieties: ["Повисла", "Пухнаста", "Карликова"],
            intelligence: CareIntelligence(
                pruningMonths: [7, 8],
                pruningTips: "ONLY prune in summer! Birch bleeds heavily if pruned in spring. Remove dead branches and light shaping only.",
                fertilizerMonths: [4, 6],
                fertilizerType: "Acidic fertilizer or ammonium sulfate. Birch prefers slightly acidic soil. Mulch with pine needles or bark.",
                youngWateringDays: 4,
                matureWateringDays: 7,
                establishedWateringDays: 14,
                yearsToMature: 3,
                harvestMonths: nil,
                yearsToBearing: nil,
                idealSoilPH: "5.0-6.5",
                sunExposure: "Full sun to partial shade",
                frostHardiness: -35,
                matureHeight: "15-25m",
                springTip: "DO NOT prune — birch bleeds sap in spring! Apply acidic mulch. Water well as leaves emerge.",
                summerTip: "Birch needs consistent moisture — don't let soil dry out completely. This is the best time to prune if needed.",
                autumnTip: "Enjoy the golden autumn foliage! Reduce watering as leaves drop. Clean up fallen leaves if they have spots (disease prevention).",
                winterTip: "Beautiful white bark stands out in winter. Protect young trunks from deer and rabbits with wire guards.",
                commonPests: ["Birch leaf miner", "Bronze birch borer", "Aphids"],
                commonDiseases: ["Birch dieback", "Rust", "Leaf spot"]
            )
        ),
        PlantSpecies(
            name: "Pine", ukrainianName: "Сосна", type: .forestTree,
            defaultWateringDays: 7,
            varieties: ["Звичайна", "Кримська", "Гірська", "Веймутова"],
            intelligence: CareIntelligence(
                pruningMonths: [5, 6],
                pruningTips: "Prune 'candles' (new growth tips) in late spring to control size. Remove dead branches any time. Never cut back into old wood — it won't regrow.",
                fertilizerMonths: [4],
                fertilizerType: "Acidic fertilizer for conifers. Pine needles naturally acidify soil — use them as mulch. Avoid high-nitrogen fertilizers.",
                youngWateringDays: 5,
                matureWateringDays: 14,
                establishedWateringDays: 30,
                yearsToMature: 4,
                harvestMonths: nil,
                yearsToBearing: nil,
                idealSoilPH: "4.5-6.0",
                sunExposure: "Full sun",
                frostHardiness: -35,
                matureHeight: "15-40m",
                springTip: "Cut candles by half to encourage bushier growth. Apply conifer fertilizer. Check for pine sawfly larvae.",
                summerTip: "Established pines rarely need water. Water young pines during extended drought. Watch for resin bleeding (sign of bark beetle).",
                autumnTip: "Normal for inner needles to turn yellow and drop — this is natural shedding. Don't worry unless outer needles yellow too.",
                winterTip: "Shake heavy snow off branches to prevent breakage. Pines are extremely cold-hardy.",
                commonPests: ["Pine bark beetle", "Pine sawfly", "Pine processionary moth"],
                commonDiseases: ["Pine needle cast", "Dothistroma blight", "Root rot"]
            )
        ),
        PlantSpecies(
            name: "Linden", ukrainianName: "Липа", type: .forestTree,
            defaultWateringDays: 7,
            varieties: ["Серцелиста", "Дрібнолиста", "Європейська"],
            intelligence: CareIntelligence(
                pruningMonths: [1, 2, 3],
                pruningTips: "Prune in late winter while dormant. Linden tolerates heavy pruning well — popular for formal shaping. Remove suckers from the base.",
                fertilizerMonths: [4, 5],
                fertilizerType: "Balanced fertilizer (NPK 10-10-10) or compost. Linden isn't fussy about soil — responds well to organic mulch.",
                youngWateringDays: 5,
                matureWateringDays: 10,
                establishedWateringDays: 21,
                yearsToMature: 4,
                harvestMonths: [6, 7],
                yearsToBearing: nil,
                idealSoilPH: "6.0-7.5",
                sunExposure: "Full sun to partial shade",
                frostHardiness: -30,
                matureHeight: "20-30m",
                springTip: "Final chance to prune before leaves emerge. Apply compost around base. Linden is a great honey tree — bees love the flowers!",
                summerTip: "Harvest linden flowers in June-July for tea (липовий чай)! Water during dry spells. Watch for aphid honeydew on leaves.",
                autumnTip: "Collect fallen leaves for compost. Apply mulch layer before winter. Check for aphid damage and plan treatment for spring.",
                winterTip: "Very hardy tree. Protect young trunk from frost cracks with white tree wrap.",
                commonPests: ["Linden aphid", "Spider mites", "Linden moth"],
                commonDiseases: ["Leaf spot", "Anthracnose", "Sooty mold (from aphids)"]
            )
        ),
        PlantSpecies(
            name: "Maple", ukrainianName: "Клен", type: .forestTree,
            defaultWateringDays: 7,
            varieties: ["Гостролистий", "Явір", "Татарський", "Цукровий"],
            intelligence: CareIntelligence(
                pruningMonths: [7, 8],
                pruningTips: "Prune in summer only — maple bleeds heavily in spring like birch. Remove dead branches and crossing limbs. Shape young trees lightly.",
                fertilizerMonths: [4, 5],
                fertilizerType: "Balanced slow-release fertilizer. Avoid over-fertilizing — maples prefer moderate nutrition. Mulch with composted leaves.",
                youngWateringDays: 5,
                matureWateringDays: 10,
                establishedWateringDays: 21,
                yearsToMature: 4,
                harvestMonths: nil,
                yearsToBearing: nil,
                idealSoilPH: "6.0-7.5",
                sunExposure: "Full sun to partial shade",
                frostHardiness: -30,
                matureHeight: "15-25m",
                springTip: "DO NOT prune — maple bleeds sap heavily! Watch for tar spot disease on emerging leaves. Begin watering young trees.",
                summerTip: "Best time to prune. Water during drought — maples can get leaf scorch in dry heat. Spectacular canopy provides great shade.",
                autumnTip: "Enjoy the stunning autumn colors! Collect seeds (helicopters) if you don't want seedlings everywhere. Apply final fertilizer.",
                winterTip: "Hardy tree. Protect young trunks from frost. Good time to plan pruning for next summer.",
                commonPests: ["Maple aphid", "Maple borer", "Scale insects"],
                commonDiseases: ["Tar spot", "Verticillium wilt", "Anthracnose"]
            )
        ),
        PlantSpecies(
            name: "Spruce", ukrainianName: "Ялина", type: .forestTree,
            defaultWateringDays: 7,
            varieties: ["Європейська", "Блакитна", "Сербська", "Коніка"],
            intelligence: CareIntelligence(
                pruningMonths: [5, 6],
                pruningTips: "Trim new growth in late spring for shaping. Never cut back to bare wood — spruce won't regrow from old branches. Remove dead lower branches as needed.",
                fertilizerMonths: [4, 5],
                fertilizerType: "Acidic conifer fertilizer. Mulch with bark chips or pine needles to maintain acidity. Avoid lime near spruce.",
                youngWateringDays: 5,
                matureWateringDays: 10,
                establishedWateringDays: 21,
                yearsToMature: 4,
                harvestMonths: nil,
                yearsToBearing: nil,
                idealSoilPH: "4.5-6.0",
                sunExposure: "Full sun",
                frostHardiness: -35,
                matureHeight: "20-40m",
                springTip: "Apply acidic fertilizer. Trim new candles to shape. Watch for spruce spider mites as weather warms.",
                summerTip: "Water young trees weekly during hot, dry weather. Check for spider mites (shake branch over white paper). Needle drop from inner branches is normal.",
                autumnTip: "Water well before ground freezes — evergreens lose moisture all winter through needles. Apply a layer of bark mulch.",
                winterTip: "Brush heavy snow off branches. Watch for salt spray damage near roads. Blue spruce varieties are especially hardy.",
                commonPests: ["Spruce spider mite", "Spruce bark beetle", "Spruce budworm"],
                commonDiseases: ["Needle cast", "Cytospora canker", "Root rot"]
            )
        ),
        PlantSpecies(
            name: "Beech", ukrainianName: "Бук", type: .forestTree,
            defaultWateringDays: 5,
            varieties: ["Лісовий", "Східний", "Пурпурний"],
            intelligence: CareIntelligence(
                pruningMonths: [2, 3, 8],
                pruningTips: "Prune in late winter or late summer. Beech responds well to pruning — excellent for hedges. Remove dead branches and shape crown gradually.",
                fertilizerMonths: [4, 5],
                fertilizerType: "Organic compost or balanced slow-release fertilizer. Beech prefers rich, well-drained soil. Leaf mold is ideal mulch.",
                youngWateringDays: 4,
                matureWateringDays: 7,
                establishedWateringDays: 14,
                yearsToMature: 4,
                harvestMonths: nil,
                yearsToBearing: nil,
                idealSoilPH: "5.5-7.0",
                sunExposure: "Full sun to partial shade",
                frostHardiness: -25,
                matureHeight: "20-35m",
                springTip: "Apply compost. Watch for beech leaf disease. Young beech benefits from some shade — it's naturally an understory tree.",
                summerTip: "Keep soil moist — beech has shallow roots and suffers in drought. Thick canopy creates deep shade underneath.",
                autumnTip: "Beautiful golden-bronze autumn color. Some leaves persist through winter (marcescent). Apply mulch before frost.",
                winterTip: "Moderate hardiness. Protect young trees from harsh winds. Dead leaves on branches provide some insulation.",
                commonPests: ["Beech scale", "Woolly beech aphid", "Bark beetles"],
                commonDiseases: ["Beech bark disease", "Leaf spot", "Phytophthora root rot"]
            )
        ),
        PlantSpecies(
            name: "Ash", ukrainianName: "Ясен", type: .forestTree,
            defaultWateringDays: 7,
            varieties: ["Звичайний", "Вузьколистий", "Пенсильванський"],
            intelligence: CareIntelligence(
                pruningMonths: [11, 12, 1, 2],
                pruningTips: "Prune while fully dormant (November-February). Remove crossing branches. Ash has a tendency to form co-dominant leaders — train to single leader when young.",
                fertilizerMonths: [4],
                fertilizerType: "Balanced fertilizer or compost. Ash is adaptable to most soils. Don't over-fertilize.",
                youngWateringDays: 5,
                matureWateringDays: 10,
                establishedWateringDays: 21,
                yearsToMature: 4,
                harvestMonths: nil,
                yearsToBearing: nil,
                idealSoilPH: "6.0-7.5",
                sunExposure: "Full sun",
                frostHardiness: -30,
                matureHeight: "20-30m",
                springTip: "Last of deciduous trees to leaf out — don't worry if it's late. Watch for emerald ash borer damage. Apply fertilizer as buds swell.",
                summerTip: "Fast grower — may need formative pruning while young. Water during drought. Ash handles urban conditions well.",
                autumnTip: "First tree to drop leaves in fall. Clean up debris to prevent disease. Good time to assess structure for winter pruning.",
                winterTip: "Best time to prune. Inspect for ash dieback symptoms (dead branches, diamond-shaped bark lesions). Very cold-hardy.",
                commonPests: ["Emerald ash borer", "Ash bark beetle", "Ash bud moth"],
                commonDiseases: ["Ash dieback (Chalara)", "Anthracnose", "Root rot"]
            )
        ),
        PlantSpecies(
            name: "Hornbeam", ukrainianName: "Граб", type: .forestTree,
            defaultWateringDays: 7,
            varieties: ["Звичайний", "Східний"],
            intelligence: CareIntelligence(
                pruningMonths: [2, 3, 8],
                pruningTips: "Excellent hedge tree — tolerates heavy shaping. Prune hedges in August for a tidy winter look. For standalone trees, minimal pruning needed.",
                fertilizerMonths: [4, 5],
                fertilizerType: "Balanced fertilizer or compost. Hornbeam is very adaptable and low-maintenance.",
                youngWateringDays: 5,
                matureWateringDays: 10,
                establishedWateringDays: 21,
                yearsToMature: 4,
                harvestMonths: nil,
                yearsToBearing: nil,
                idealSoilPH: "5.5-7.5",
                sunExposure: "Full sun to full shade",
                frostHardiness: -28,
                matureHeight: "15-25m",
                springTip: "Formative prune before leaves emerge. Apply compost. Hornbeam leafs out early — one of the first signs of spring.",
                summerTip: "Very drought-tolerant once established. August is good for hedge trimming. Dense canopy provides excellent shade.",
                autumnTip: "Leaves turn golden-yellow. Like beech, some leaves persist through winter. Low maintenance in autumn.",
                winterTip: "Very hardy and problem-free. Retained brown leaves add winter interest. Plan structural pruning if needed.",
                commonPests: ["Hornbeam moth", "Aphids", "Scale insects"],
                commonDiseases: ["Coral spot", "Powdery mildew", "Leaf spot"]
            )
        ),
        PlantSpecies(
            name: "Alder", ukrainianName: "Вільха", type: .forestTree,
            defaultWateringDays: 5,
            varieties: ["Чорна", "Сіра"],
            intelligence: CareIntelligence(
                pruningMonths: [11, 12, 1],
                pruningTips: "Prune in dormant season. Alder fixes nitrogen in soil (like legumes) — great companion for other trees. Remove lower branches for clearance.",
                fertilizerMonths: [],
                fertilizerType: "Usually doesn't need fertilizer — alder fixes its own nitrogen from the air! Just mulch with organic matter.",
                youngWateringDays: 4,
                matureWateringDays: 7,
                establishedWateringDays: 14,
                yearsToMature: 3,
                harvestMonths: nil,
                yearsToBearing: nil,
                idealSoilPH: "5.0-7.0",
                sunExposure: "Full sun to partial shade",
                frostHardiness: -30,
                matureHeight: "15-25m",
                springTip: "Catkins appear before leaves. Alder improves soil for nearby plants. Great choice for wet areas where other trees struggle.",
                summerTip: "Loves moisture — perfect near ponds or streams. One of the few trees that thrives in waterlogged soil.",
                autumnTip: "Leaves drop early and green (don't change color much). Tiny cones remain through winter. Seeds feed birds.",
                winterTip: "Very hardy. Good time to prune. Small woody cones on bare branches are attractive winter feature.",
                commonPests: ["Alder beetle", "Alder woolly aphid"],
                commonDiseases: ["Phytophthora (alder disease)", "Leaf curl"]
            )
        ),
    ]

    // MARK: - Fruit Trees (Плодові дерева)
    static let fruitTrees: [PlantSpecies] = [
        PlantSpecies(
            name: "Cherry", ukrainianName: "Вишня", type: .fruitTree,
            defaultWateringDays: 7,
            varieties: ["Шпанка", "Любська", "Гріот київський", "Молодіжна", "Тургенівка"],
            intelligence: CareIntelligence(
                pruningMonths: [3, 7, 8],
                pruningTips: "Light pruning after harvest (July-August) to prevent silver leaf disease. In March, remove dead and crossing branches. Never prune in autumn — wounds heal slowly.",
                fertilizerMonths: [3, 4, 6],
                fertilizerType: "Early spring: NPK 10-10-10. After flowering: potassium-rich fertilizer for fruit development. Avoid excess nitrogen — causes soft growth prone to disease.",
                youngWateringDays: 5,
                matureWateringDays: 7,
                establishedWateringDays: 14,
                yearsToMature: 3,
                harvestMonths: [6, 7],
                yearsToBearing: 3,
                idealSoilPH: "6.0-7.0",
                sunExposure: "Full sun",
                frostHardiness: -25,
                matureHeight: "4-8m",
                springTip: "Protect blossoms from late frost with fleece. Apply nitrogen fertilizer as buds swell. Watch for cherry blossom blight.",
                summerTip: "Harvest when fully ripe (dark red). Water deeply during fruit development. Prune after harvest to shape crown and improve air circulation.",
                autumnTip: "Clean up fallen fruit to prevent brown rot. Apply potash fertilizer. Whitewash trunk to prevent frost cracks.",
                winterTip: "Inspect for canker on branches. Plan spring pruning. Apply dormant oil spray against overwintering pests.",
                commonPests: ["Cherry fruit fly", "Black cherry aphid", "Cherry bark moth"],
                commonDiseases: ["Cherry leaf spot", "Brown rot", "Silver leaf disease"]
            )
        ),
        PlantSpecies(
            name: "Sweet Cherry", ukrainianName: "Черешня", type: .fruitTree,
            defaultWateringDays: 7,
            varieties: ["Великоплідна", "Валерій Чкалов", "Дрогана жовта", "Регіна", "Ревна"],
            intelligence: CareIntelligence(
                pruningMonths: [4, 7, 8],
                pruningTips: "Prune after harvest or in early spring (after frost risk). Train to open center or vase shape. Sweet cherry grows vigorously — control height annually.",
                fertilizerMonths: [3, 6],
                fertilizerType: "Spring: balanced NPK. After harvest: potassium and phosphorus for next year's buds. Calcium prevents fruit cracking.",
                youngWateringDays: 5,
                matureWateringDays: 7,
                establishedWateringDays: 14,
                yearsToMature: 4,
                harvestMonths: [6, 7],
                yearsToBearing: 4,
                idealSoilPH: "6.0-7.0",
                sunExposure: "Full sun",
                frostHardiness: -22,
                matureHeight: "6-12m",
                springTip: "Flowers are frost-sensitive — cover with fleece if late frost threatens. Apply nitrogen fertilizer. Watch for bacterial canker.",
                summerTip: "Net trees to protect fruit from birds. Harvest when firm and sweet. Don't over-water during ripening — causes cracking.",
                autumnTip: "Remove mummified fruit. Apply potassium fertilizer. Whitewash trunk. Clean up leaves to prevent brown rot.",
                winterTip: "Less hardy than sour cherry — protect young trees from extreme cold. Inspect for bacterial canker (amber gum on bark).",
                commonPests: ["Cherry fruit fly", "Birds", "Cherry blossom weevil"],
                commonDiseases: ["Bacterial canker", "Brown rot", "Cracking (from rain during ripening)"]
            )
        ),
        PlantSpecies(
            name: "Apple", ukrainianName: "Яблуня", type: .fruitTree,
            defaultWateringDays: 7,
            varieties: ["Антонівка", "Голден Делішес", "Семеренко", "Ренет Симиренка", "Гала", "Фуджі"],
            intelligence: CareIntelligence(
                pruningMonths: [1, 2, 3],
                pruningTips: "Prune in winter while dormant. Open up the center for light and air. Remove water sprouts (vertical shoots) and crossing branches. Summer tip: remove excess fruit in June (thin to 1 per cluster).",
                fertilizerMonths: [3, 4, 6, 9],
                fertilizerType: "Spring: nitrogen-rich (urea or ammonium nitrate). Summer: balanced NPK after fruit set. Autumn: potassium + phosphorus for winter hardiness.",
                youngWateringDays: 5,
                matureWateringDays: 7,
                establishedWateringDays: 14,
                yearsToMature: 4,
                harvestMonths: [8, 9, 10],
                yearsToBearing: 3,
                idealSoilPH: "6.0-7.0",
                sunExposure: "Full sun",
                frostHardiness: -30,
                matureHeight: "4-10m",
                springTip: "Spray with copper fungicide at bud swell against scab. Thin fruit clusters to 1 apple per cluster in June. Apply nitrogen fertilizer.",
                summerTip: "Water consistently during fruit development. Support heavily laden branches with props. Watch for codling moth — trap from May.",
                autumnTip: "Harvest based on variety (August-October). Store late varieties in cool, dark place. Clean up windfalls. Apply potash fertilizer.",
                winterTip: "Best pruning time! Remove 20-30% of growth. Apply dormant oil spray. Whitewash trunk. Wrap young bark to prevent rabbit/hare damage.",
                commonPests: ["Codling moth", "Apple aphid", "Apple sawfly", "Apple blossom weevil"],
                commonDiseases: ["Apple scab", "Powdery mildew", "Fire blight", "Canker"]
            )
        ),
        PlantSpecies(
            name: "Pear", ukrainianName: "Груша", type: .fruitTree,
            defaultWateringDays: 7,
            varieties: ["Вільямс", "Конференція", "Ліщина", "Бере Боск", "Ноябрська"],
            intelligence: CareIntelligence(
                pruningMonths: [1, 2, 3],
                pruningTips: "Prune in winter. Pear naturally grows upright — spread branches with weights or ties for better fruiting. Remove water sprouts. Less pruning needed than apple.",
                fertilizerMonths: [3, 4, 6],
                fertilizerType: "Similar to apple but less nitrogen — excess causes fire blight susceptibility. Potassium-rich fertilizer for fruit quality.",
                youngWateringDays: 5,
                matureWateringDays: 7,
                establishedWateringDays: 14,
                yearsToMature: 4,
                harvestMonths: [8, 9, 10],
                yearsToBearing: 4,
                idealSoilPH: "6.0-7.0",
                sunExposure: "Full sun",
                frostHardiness: -28,
                matureHeight: "5-12m",
                springTip: "Watch for fire blight (blackened shoots that look 'burned'). Remove infected branches 30cm below damage. Apply copper spray at bud break.",
                summerTip: "Water deeply during fruit development. Thin fruit if heavily loaded. Pick summer varieties when firm-ripe — they ripen off the tree.",
                autumnTip: "Late varieties: pick when stem separates easily. Store in cool conditions. Clean up fallen fruit. Apply mulch.",
                winterTip: "Prune to maintain open center. Pear is very cold-hardy. Inspect for canker and fire blight scars.",
                commonPests: ["Pear psylla", "Codling moth", "Pear midge"],
                commonDiseases: ["Fire blight", "Pear scab", "Brown rot", "Pear rust"]
            )
        ),
        PlantSpecies(
            name: "Plum", ukrainianName: "Слива", type: .fruitTree,
            defaultWateringDays: 7,
            varieties: ["Угорка", "Ренклод", "Синя птиця", "Стенлі", "Президент"],
            intelligence: CareIntelligence(
                pruningMonths: [3, 4, 7],
                pruningTips: "Prune in spring as buds open (to prevent silver leaf disease). Summer prune to remove water sprouts. Keep tree open for light. Plum suckers from rootstock — remove them!",
                fertilizerMonths: [3, 6],
                fertilizerType: "Moderate nitrogen in spring. Potassium after flowering for fruit sweetness. Don't over-feed — plum grows vigorously enough.",
                youngWateringDays: 5,
                matureWateringDays: 7,
                establishedWateringDays: 14,
                yearsToMature: 3,
                harvestMonths: [7, 8, 9],
                yearsToBearing: 3,
                idealSoilPH: "6.0-7.0",
                sunExposure: "Full sun",
                frostHardiness: -27,
                matureHeight: "4-8m",
                springTip: "Thin fruit after 'June drop' to improve size. Spray against plum moth. Prune NOW — never in winter (silver leaf risk).",
                summerTip: "Harvest when fruit pulls away easily and is soft. Support heavy branches. Water stress reduces next year's crop.",
                autumnTip: "Remove all mummified fruit from tree AND ground (brown rot prevention). Apply potash. Clean up fallen leaves.",
                winterTip: "DO NOT prune in winter — risk of silver leaf disease! Inspect for bacterial canker. Plan spring pruning.",
                commonPests: ["Plum moth", "Plum sawfly", "Aphids"],
                commonDiseases: ["Silver leaf", "Brown rot", "Bacterial canker", "Plum pox virus"]
            )
        ),
        PlantSpecies(
            name: "Apricot", ukrainianName: "Абрикос", type: .fruitTree,
            defaultWateringDays: 10,
            varieties: ["Краснощокий", "Ананасний", "Мелітопольський ранній", "Шалах"],
            intelligence: CareIntelligence(
                pruningMonths: [3, 8],
                pruningTips: "Prune in March (after frost risk) or August after harvest. Keep tree compact — apricot is prone to breaking under heavy crop. Thin branches for air circulation.",
                fertilizerMonths: [3, 6],
                fertilizerType: "Moderate balanced fertilizer. Calcium is important for fruit quality. Don't over-fertilize with nitrogen.",
                youngWateringDays: 5,
                matureWateringDays: 10,
                establishedWateringDays: 21,
                yearsToMature: 3,
                harvestMonths: [7, 8],
                yearsToBearing: 3,
                idealSoilPH: "6.0-7.5",
                sunExposure: "Full sun, sheltered from cold wind",
                frostHardiness: -20,
                matureHeight: "4-8m",
                springTip: "CRITICAL: apricot blooms very early — frost is the #1 enemy. Cover with fleece during late frost. Plant in a warm, sheltered spot.",
                summerTip: "Harvest when fruit is golden and slightly soft. Thin heavy crops early. Deep water during dry spells but let soil dry between.",
                autumnTip: "Remove fallen fruit. Apply whitewash to trunk. Reduce watering to harden wood before winter.",
                winterTip: "Less hardy than most fruit trees. Protect trunk from frost cracks. Avoid north-facing planting sites. Pray for no late spring frost!",
                commonPests: ["Plum moth", "Aphids", "Shot hole borer"],
                commonDiseases: ["Monilia (blossom blight)", "Shot hole disease", "Gummosis", "Bacterial canker"]
            )
        ),
        PlantSpecies(
            name: "Peach", ukrainianName: "Персик", type: .fruitTree,
            defaultWateringDays: 7,
            varieties: ["Київський ранній", "Редхейвен", "Донецький жовтий", "Золотий ювілей", "Білий лебідь"],
            intelligence: CareIntelligence(
                pruningMonths: [3, 4],
                pruningTips: "Prune in spring as flower buds swell (you can see which are fruit buds). Open vase shape is ideal. Peach fruits on last year's wood — remove old fruited branches.",
                fertilizerMonths: [3, 5, 7],
                fertilizerType: "Higher nitrogen than other fruit trees — peach is a heavy feeder. Spring: NPK 12-12-12. Summer: potassium for fruit quality.",
                youngWateringDays: 4,
                matureWateringDays: 7,
                establishedWateringDays: 14,
                yearsToMature: 3,
                harvestMonths: [7, 8, 9],
                yearsToBearing: 2,
                idealSoilPH: "6.0-7.0",
                sunExposure: "Full sun, warm sheltered spot",
                frostHardiness: -18,
                matureHeight: "3-6m",
                springTip: "Spray against peach leaf curl BEFORE buds open (copper fungicide). Thin fruit aggressively — leave 15cm between fruit for good size.",
                summerTip: "Peach needs consistent water during fruit development. Harvest when fruit is fragrant and gives slightly to pressure. Enjoys heat!",
                autumnTip: "After leaf fall, spray copper against leaf curl (most critical treatment!). Clean up ALL fallen leaves. Apply potash.",
                winterTip: "Least hardy common fruit tree. Protect from cold wind. In northern Ukraine, consider growing against a south-facing wall.",
                commonPests: ["Peach moth", "Aphids", "Scale insects"],
                commonDiseases: ["Peach leaf curl", "Brown rot", "Powdery mildew", "Bacterial spot"]
            )
        ),
        PlantSpecies(
            name: "Walnut", ukrainianName: "Горіх", type: .fruitTree,
            defaultWateringDays: 10,
            varieties: ["Волоський", "Ідеал", "Буковинський", "Великоплідний"],
            intelligence: CareIntelligence(
                pruningMonths: [8, 9],
                pruningTips: "Prune in late summer ONLY — walnut bleeds heavily in spring. Minimal pruning needed. Remove dead branches and low limbs for clearance. Walnuts self-shape well.",
                fertilizerMonths: [4],
                fertilizerType: "Walnut rarely needs fertilizer in good soil. Apply compost around drip line. Avoid fertilizers high in chloride.",
                youngWateringDays: 7,
                matureWateringDays: 14,
                establishedWateringDays: 30,
                yearsToMature: 5,
                harvestMonths: [9, 10],
                yearsToBearing: 5,
                idealSoilPH: "6.0-7.5",
                sunExposure: "Full sun",
                frostHardiness: -25,
                matureHeight: "15-25m",
                springTip: "DO NOT prune! Walnut leafs out late — don't worry. Roots release juglone (toxic to some plants) — keep tomatoes, peppers far away.",
                summerTip: "Deep water during dry spells. Best time to prune if needed (August-September). Giant tree provides excellent shade.",
                autumnTip: "Harvest nuts when husks crack open. Dry nuts in a warm, airy place for 2 weeks. Wear gloves — walnut husks stain everything brown!",
                winterTip: "Fairly hardy. Young trees may need trunk protection. Walnut wood is extremely valuable — protect from storm damage.",
                commonPests: ["Walnut husk fly", "Codling moth", "Walnut aphid"],
                commonDiseases: ["Walnut blight", "Anthracnose", "Root rot"]
            )
        ),
        PlantSpecies(
            name: "Mulberry", ukrainianName: "Шовковиця", type: .fruitTree,
            defaultWateringDays: 10,
            varieties: ["Біла", "Чорна", "Червона"],
            intelligence: CareIntelligence(
                pruningMonths: [12, 1, 2],
                pruningTips: "Prune in winter while dormant. Mulberry bleeds in spring. Can be kept small with hard pruning — very resilient. Remove low branches that spread fruit mess.",
                fertilizerMonths: [3, 4],
                fertilizerType: "Light feeding only — mulberry is naturally vigorous. Compost is sufficient. Over-fertilizing produces too many leaves, less fruit.",
                youngWateringDays: 5,
                matureWateringDays: 10,
                establishedWateringDays: 30,
                yearsToMature: 3,
                harvestMonths: [6, 7],
                yearsToBearing: 3,
                idealSoilPH: "6.0-7.0",
                sunExposure: "Full sun",
                frostHardiness: -25,
                matureHeight: "8-15m",
                springTip: "Very easy tree — almost maintenance-free. Don't prune now (bleeds). Watch for new shoots — mulberry grows fast.",
                summerTip: "Harvest berries daily — they're very perishable! Spread a sheet under tree and shake branches. Warning: fruit stains walkways, cars, clothes!",
                autumnTip: "Clean up fallen fruit. Apply light compost. Mulberry is very adaptable — tolerates poor soil, drought, and pollution.",
                winterTip: "Prune now if needed. Very tough tree. Popular in Ukrainian villages — often grows to 100+ years. Little winter care needed.",
                commonPests: ["Whitefly", "Scale insects", "Birds (love the fruit!)"],
                commonDiseases: ["Bacterial blight", "Leaf spot", "Root rot (rare)"]
            )
        ),
        PlantSpecies(
            name: "Quince", ukrainianName: "Айва", type: .fruitTree,
            defaultWateringDays: 10,
            varieties: ["Звичайна", "Японська", "Ананасна"],
            intelligence: CareIntelligence(
                pruningMonths: [1, 2, 3],
                pruningTips: "Prune in winter. Train to open center. Remove crossing branches and suckers. Quince naturally grows as a large bush — can be trained to a small tree.",
                fertilizerMonths: [3, 6],
                fertilizerType: "Light balanced fertilizer in spring. Potassium after flowering. Quince isn't a heavy feeder.",
                youngWateringDays: 5,
                matureWateringDays: 10,
                establishedWateringDays: 21,
                yearsToMature: 3,
                harvestMonths: [10, 11],
                yearsToBearing: 3,
                idealSoilPH: "6.0-7.5",
                sunExposure: "Full sun",
                frostHardiness: -22,
                matureHeight: "4-8m",
                springTip: "Beautiful pink-white blossoms. Apply fertilizer. Quince blooms late — less frost risk than apricot or peach.",
                summerTip: "Relatively low-maintenance. Water during drought. Fruit develops slowly — stays hard and green until autumn.",
                autumnTip: "Harvest after first light frost for best flavor. Fruit is hard and tart raw — cook into jam (айвове варення), paste, or bake. Aromatic!",
                winterTip: "Moderate hardiness. Protect young trees in northern Ukraine. Prune to maintain shape. Remove any fire blight damage.",
                commonPests: ["Codling moth", "Aphids", "Leaf miners"],
                commonDiseases: ["Fire blight", "Leaf blight", "Brown rot"]
            )
        ),
    ]

    // MARK: - Bushes (Кущі)
    static let bushes: [PlantSpecies] = [
        PlantSpecies(
            name: "Currant", ukrainianName: "Смородина", type: .bush,
            defaultWateringDays: 5,
            varieties: ["Чорна Перлина", "Червона", "Біла", "Ядреная", "Добриня"],
            intelligence: CareIntelligence(
                pruningMonths: [2, 3, 11],
                pruningTips: "Remove branches older than 3 years (they darken and produce less). Keep 8-12 main stems. Cut at base — don't shorten. Renew 1/3 of the bush each year.",
                fertilizerMonths: [3, 4, 6],
                fertilizerType: "High-potassium fertilizer for fruiting. Black currant loves nitrogen — more than red/white. Mulch with compost annually.",
                youngWateringDays: 3,
                matureWateringDays: 5,
                establishedWateringDays: 7,
                yearsToMature: 2,
                harvestMonths: [7, 8],
                yearsToBearing: 2,
                idealSoilPH: "6.0-7.0",
                sunExposure: "Full sun to partial shade",
                frostHardiness: -30,
                matureHeight: "1-2m",
                springTip: "Apply nitrogen fertilizer as growth starts. Mulch thickly to retain moisture. Watch for big bud mite (swollen round buds — remove them!).",
                summerTip: "Water well during fruit development — consistent moisture = bigger berries. Harvest when fully colored. Black currant is rich in vitamin C!",
                autumnTip: "After harvest, assess which old branches to remove. Apply potash fertilizer. Plant new bushes in October-November.",
                winterTip: "Very hardy. Prune now or in early spring. Take hardwood cuttings for new plants. Virtually indestructible in Ukrainian climate.",
                commonPests: ["Big bud mite", "Currant aphid", "Currant sawfly"],
                commonDiseases: ["American gooseberry mildew", "Leaf spot", "Reversion virus"]
            )
        ),
        PlantSpecies(
            name: "Raspberry", ukrainianName: "Малина", type: .bush,
            defaultWateringDays: 4,
            varieties: ["Ремонтантна", "Полана", "Гусар", "Геракл", "Жовтий гігант"],
            intelligence: CareIntelligence(
                pruningMonths: [2, 3, 11],
                pruningTips: "Summer varieties: cut fruited canes to ground after harvest. Remontant varieties: cut ALL canes to ground in late autumn for one big autumn crop, OR keep strongest for early summer + autumn crops.",
                fertilizerMonths: [3, 4, 6],
                fertilizerType: "High nitrogen in spring (urea). Potassium during fruiting. Heavy mulch with compost or manure — raspberry is a hungry plant!",
                youngWateringDays: 3,
                matureWateringDays: 4,
                establishedWateringDays: 5,
                yearsToMature: 1,
                harvestMonths: [6, 7, 8, 9],
                yearsToBearing: 1,
                idealSoilPH: "5.5-6.5",
                sunExposure: "Full sun",
                frostHardiness: -28,
                matureHeight: "1.5-2.5m",
                springTip: "Tie new canes to supports. Apply heavy mulch and nitrogen fertilizer. Thin canes to 8-10 per meter for air circulation.",
                summerTip: "Pick every 2-3 days when ripe — berries don't wait! Water consistently. Remontant varieties start autumn crop in August.",
                autumnTip: "Cut summer-fruited canes to ground. For remontant: decide strategy (cut all or keep some). Mulch heavily for winter protection.",
                winterTip: "Canes are fairly hardy. In harsh winters, bend canes down and cover with snow/mulch. Plan trellis/support maintenance.",
                commonPests: ["Raspberry beetle", "Aphids", "Spider mites"],
                commonDiseases: ["Raspberry cane blight", "Grey mold (Botrytis)", "Root rot", "Raspberry mosaic virus"]
            )
        ),
        PlantSpecies(
            name: "Strawberry", ukrainianName: "Полуниця", type: .bush,
            defaultWateringDays: 3,
            varieties: ["Вікторія", "Полка", "Хоней", "Альбіон", "Елізабет"],
            intelligence: CareIntelligence(
                pruningMonths: [8, 9],
                pruningTips: "After harvest, remove old leaves (but not the growing point!). Cut off runners unless you want new plants. Replace entire bed every 3-4 years for best yields.",
                fertilizerMonths: [3, 4, 8],
                fertilizerType: "Balanced fertilizer in spring. After harvest: phosphorus and potassium for next year's buds. Avoid excess nitrogen — causes leafy growth, fewer berries.",
                youngWateringDays: 2,
                matureWateringDays: 3,
                establishedWateringDays: 4,
                yearsToMature: 1,
                harvestMonths: [5, 6, 7],
                yearsToBearing: 1,
                idealSoilPH: "5.5-6.5",
                sunExposure: "Full sun",
                frostHardiness: -20,
                matureHeight: "0.2-0.3m",
                springTip: "Remove dead leaves. Apply straw mulch under plants (prevents mud splash on berries + suppresses weeds). Fertilize as growth starts.",
                summerTip: "Water at soil level (not on leaves — prevents disease). Pick every 2 days. Remove runners unless propagating. Net against birds.",
                autumnTip: "Trim old leaves after harvest. Plant new beds in August-September. Apply mulch for winter. Rooted runners make free new plants!",
                winterTip: "Cover with straw or agrofabric in cold regions. Strawberry crowns can freeze in severe winters without snow cover.",
                commonPests: ["Strawberry mite", "Slugs", "Birds", "Weevils"],
                commonDiseases: ["Grey mold (Botrytis)", "Powdery mildew", "Verticillium wilt", "Leaf spot"]
            )
        ),
        PlantSpecies(
            name: "Blueberry", ukrainianName: "Лохина", type: .bush,
            defaultWateringDays: 3,
            varieties: ["Блюкроп", "Патріот", "Дюк", "Спартан", "Нортланд"],
            intelligence: CareIntelligence(
                pruningMonths: [2, 3],
                pruningTips: "Remove branches older than 5 years (thickest, darkest). Keep 6-8 main stems. Tip-prune young branches to encourage branching. Don't prune first 2 years.",
                fertilizerMonths: [3, 4, 5],
                fertilizerType: "ACIDIC fertilizer ONLY — ammonium sulfate or special blueberry fertilizer. NEVER use lime or alkaline fertilizers. Mulch with pine needles or sawdust.",
                youngWateringDays: 2,
                matureWateringDays: 3,
                establishedWateringDays: 5,
                yearsToMature: 3,
                harvestMonths: [7, 8],
                yearsToBearing: 2,
                idealSoilPH: "4.0-5.5",
                sunExposure: "Full sun",
                frostHardiness: -28,
                matureHeight: "1-2.5m",
                springTip: "Apply sulfur or acidic fertilizer — blueberry MUST have acidic soil (pH 4.0-5.5). Test soil pH annually. Mulch with pine bark or sawdust.",
                summerTip: "Water with rainwater if possible (tap water is often too alkaline). Berries ripen over 2-3 weeks — pick every few days. Blue = ripe!",
                autumnTip: "Foliage turns brilliant red — very decorative! Apply pine needle mulch for winter acidity. Stop fertilizing after August.",
                winterTip: "Very hardy. Minimal winter care. This is the best time to prune old unproductive wood. Check soil pH and plan amendments.",
                commonPests: ["Birds (biggest threat!)", "Blueberry maggot", "Aphids"],
                commonDiseases: ["Mummy berry", "Botrytis blight", "Stem canker", "Chlorosis (from alkaline soil!)"]
            )
        ),
        PlantSpecies(
            name: "Gooseberry", ukrainianName: "Аґрус", type: .bush,
            defaultWateringDays: 5,
            varieties: ["Машенька", "Фінік", "Чорний негус", "Малахіт"],
            intelligence: CareIntelligence(
                pruningMonths: [2, 3, 11],
                pruningTips: "Similar to currant — remove branches older than 4 years. Keep center open for air circulation (mildew prevention). Thorns make pruning tricky — wear thick gloves!",
                fertilizerMonths: [3, 6],
                fertilizerType: "Potassium-rich fertilizer (gooseberry loves potash). Avoid excess nitrogen — promotes mildew-prone soft growth. Mulch with compost.",
                youngWateringDays: 3,
                matureWateringDays: 5,
                establishedWateringDays: 7,
                yearsToMature: 2,
                harvestMonths: [6, 7],
                yearsToBearing: 2,
                idealSoilPH: "6.0-7.0",
                sunExposure: "Full sun to partial shade",
                frostHardiness: -30,
                matureHeight: "1-1.5m",
                springTip: "Apply potash fertilizer. Watch for gooseberry sawfly caterpillars — they can strip leaves in days! Inspect undersides of leaves.",
                summerTip: "Harvest when berries are full-sized. Green = tart (good for jam). Let ripen for sweet eating. Water during dry spells.",
                autumnTip: "Prune after leaf fall. Remove crossing branches and old wood. Apply mulch. Very low-maintenance plant.",
                winterTip: "Extremely hardy — one of the toughest berry bushes. Prune now if you didn't in autumn. Almost impossible to kill.",
                commonPests: ["Gooseberry sawfly", "Aphids", "Gooseberry mite"],
                commonDiseases: ["American gooseberry mildew", "Leaf spot", "Grey mold"]
            )
        ),
        PlantSpecies(
            name: "Blackberry", ukrainianName: "Ожина", type: .bush,
            defaultWateringDays: 4,
            varieties: ["Торнфрі", "Блек Сатін", "Натчез", "Честер"],
            intelligence: CareIntelligence(
                pruningMonths: [9, 10, 2],
                pruningTips: "Cut fruited canes to ground immediately after harvest. Tie new canes to support. Thornless varieties are much easier to manage! Tip-prune new canes in summer to encourage branching.",
                fertilizerMonths: [3, 4, 6],
                fertilizerType: "Balanced NPK in spring. Potassium during fruiting. Mulch heavily with compost — blackberry is a hungry plant.",
                youngWateringDays: 3,
                matureWateringDays: 4,
                establishedWateringDays: 5,
                yearsToMature: 1,
                harvestMonths: [7, 8, 9],
                yearsToBearing: 2,
                idealSoilPH: "5.5-7.0",
                sunExposure: "Full sun",
                frostHardiness: -22,
                matureHeight: "1.5-3m",
                springTip: "Tie new canes to trellis/support. Apply nitrogen fertilizer and thick mulch. Check for winter damage on canes.",
                summerTip: "Pick berries when they turn fully black and pull off easily. Water consistently for bigger berries. Canes grow vigorously — train regularly.",
                autumnTip: "Cut all fruited canes to ground. Tie new canes for next year. In cold regions, lay thornless varieties down and cover with mulch.",
                winterTip: "Thornless varieties are less hardy — protect in harsh winters. Thorny varieties are tougher. Prune dead/damaged canes.",
                commonPests: ["Raspberry beetle", "Spider mites", "Aphids"],
                commonDiseases: ["Cane blight", "Grey mold", "Anthracnose", "Orange rust"]
            )
        ),
        PlantSpecies(
            name: "Sea Buckthorn", ukrainianName: "Обліпиха", type: .bush,
            defaultWateringDays: 7,
            varieties: ["Чуйська", "Золотий початок", "Московська красуня"],
            intelligence: CareIntelligence(
                pruningMonths: [3, 4],
                pruningTips: "Remove dead branches in early spring. Sea buckthorn can be shaped but recovers slowly. Need both male and female plants for fruit (1 male per 5-6 females).",
                fertilizerMonths: [4],
                fertilizerType: "Barely needs fertilizer — fixes nitrogen like alder! Light compost is sufficient. Too much fertilizer reduces fruiting.",
                youngWateringDays: 5,
                matureWateringDays: 7,
                establishedWateringDays: 14,
                yearsToMature: 2,
                harvestMonths: [8, 9],
                yearsToBearing: 3,
                idealSoilPH: "6.0-7.5",
                sunExposure: "Full sun",
                frostHardiness: -35,
                matureHeight: "2-5m",
                springTip: "Light pruning only. Check that you have at least one male plant nearby for pollination. Fertilizer rarely needed.",
                summerTip: "Berries are VERY difficult to pick (sharp thorns + berries burst easily). Cut whole branches and freeze, then shake berries off. Extremely nutritious fruit!",
                autumnTip: "Harvest in September. Sea buckthorn oil is incredibly valuable medicinally. Plant is almost indestructible — tolerates salt, wind, poor soil.",
                winterTip: "One of the hardiest plants in the garden (-35°C!). Zero winter care needed. Spreads via suckers — control if needed.",
                commonPests: ["Sea buckthorn fly", "Aphids"],
                commonDiseases: ["Fusarium wilt", "Verticillium wilt (rare)"]
            )
        ),
    ]

    // MARK: - All Species
    static let all: [PlantSpecies] = forestTrees + fruitTrees + bushes

    // MARK: - Helper: Get species by type
    static func species(for type: PlantType) -> [PlantSpecies] {
        switch type {
        case .forestTree: return forestTrees
        case .fruitTree:  return fruitTrees
        case .bush:       return bushes
        }
    }

    // MARK: - Helper: Find species by name
    static func find(name: String) -> PlantSpecies? {
        all.first { $0.name == name }
    }
}
