import Foundation

// MARK: - Plant Catalog
// This is like a built-in encyclopedia of plants and their varieties.
// When a user adds a new plant, they pick from this catalog.
// Each plant has a list of known varieties (sorted by Ukrainian region popularity).

struct PlantSpecies: Identifiable, Codable {
    var id = UUID()
    var name: String              // e.g. "Cherry"
    var ukrainianName: String     // e.g. "Вишня"
    var type: PlantType           // e.g. .fruitTree
    var defaultWateringDays: Int  // suggested watering frequency
    var varieties: [String]       // list of varieties to choose from
}

// MARK: - The Full Catalog
// All plants the user can choose from, organized by type.
// The user can also type a custom variety if theirs isn't listed.

struct PlantCatalog {

    // MARK: - Herbs (Трави)
    static let herbs: [PlantSpecies] = [
        PlantSpecies(
            name: "Basil", ukrainianName: "Базилік", type: .herb,
            defaultWateringDays: 2,
            varieties: ["Солодкий", "Фіолетовий", "Лимонний", "Тайський"]
        ),
        PlantSpecies(
            name: "Dill", ukrainianName: "Кріп", type: .herb,
            defaultWateringDays: 3,
            varieties: ["Грибовський", "Лісногородський", "Алігатор"]
        ),
        PlantSpecies(
            name: "Parsley", ukrainianName: "Петрушка", type: .herb,
            defaultWateringDays: 3,
            varieties: ["Листова", "Кучерява", "Коренева"]
        ),
        PlantSpecies(
            name: "Mint", ukrainianName: "М'ята", type: .herb,
            defaultWateringDays: 2,
            varieties: ["Перцева", "Колосиста", "Лимонна"]
        ),
        PlantSpecies(
            name: "Thyme", ukrainianName: "Чебрець", type: .herb,
            defaultWateringDays: 5,
            varieties: ["Звичайний", "Лимонний", "Повзучий"]
        ),
        PlantSpecies(
            name: "Rosemary", ukrainianName: "Розмарин", type: .herb,
            defaultWateringDays: 7,
            varieties: ["Лікарський", "Простратус"]
        ),
        PlantSpecies(
            name: "Cilantro", ukrainianName: "Коріандр", type: .herb,
            defaultWateringDays: 3,
            varieties: ["Янтар", "Дебют", "Стимул"]
        ),
    ]

    // MARK: - Vegetables (Овочі)
    static let vegetables: [PlantSpecies] = [
        PlantSpecies(
            name: "Tomato", ukrainianName: "Помідор", type: .vegetable,
            defaultWateringDays: 3,
            varieties: ["Бичаче серце", "Де Барао", "Чері", "Сливка", "Рожевий гігант"]
        ),
        PlantSpecies(
            name: "Cucumber", ukrainianName: "Огірок", type: .vegetable,
            defaultWateringDays: 2,
            varieties: ["Ніжинський", "Конкурент", "Паризький корнішон", "Маша F1"]
        ),
        PlantSpecies(
            name: "Pepper", ukrainianName: "Перець", type: .vegetable,
            defaultWateringDays: 3,
            varieties: ["Болгарський", "Гострий", "Калифорнійське диво", "Ратунда"]
        ),
        PlantSpecies(
            name: "Potato", ukrainianName: "Картопля", type: .vegetable,
            defaultWateringDays: 7,
            varieties: ["Скарб", "Рів'єра", "Белароза", "Тирас", "Невська"]
        ),
        PlantSpecies(
            name: "Cabbage", ukrainianName: "Капуста", type: .vegetable,
            defaultWateringDays: 4,
            varieties: ["Білоголова", "Червоноголова", "Цвітна", "Броколі", "Пекінська"]
        ),
        PlantSpecies(
            name: "Carrot", ukrainianName: "Морква", type: .vegetable,
            defaultWateringDays: 4,
            varieties: ["Нантська", "Шантане", "Вітамінна", "Королева осені"]
        ),
        PlantSpecies(
            name: "Beet", ukrainianName: "Буряк", type: .vegetable,
            defaultWateringDays: 5,
            varieties: ["Бордо", "Детройт", "Циліндра", "Червона куля"]
        ),
        PlantSpecies(
            name: "Onion", ukrainianName: "Цибуля", type: .vegetable,
            defaultWateringDays: 5,
            varieties: ["Штутгартер Різен", "Ред Барон", "Халцедон", "Глобус"]
        ),
        PlantSpecies(
            name: "Garlic", ukrainianName: "Часник", type: .vegetable,
            defaultWateringDays: 7,
            varieties: ["Любаша", "Софіївський", "Озимий", "Яровий"]
        ),
        PlantSpecies(
            name: "Zucchini", ukrainianName: "Кабачок", type: .vegetable,
            defaultWateringDays: 4,
            varieties: ["Цукеша", "Грибовський", "Золотинка", "Скворушка"]
        ),
        PlantSpecies(
            name: "Pumpkin", ukrainianName: "Гарбуз", type: .vegetable,
            defaultWateringDays: 5,
            varieties: ["Мускатний", "Стофунтовий", "Український багатоплідний"]
        ),
    ]

    // MARK: - Flowers (Квіти)
    static let flowers: [PlantSpecies] = [
        PlantSpecies(
            name: "Sunflower", ukrainianName: "Соняшник", type: .flower,
            defaultWateringDays: 5,
            varieties: ["Декоративний", "Ведмедик", "Промінь"]
        ),
        PlantSpecies(
            name: "Rose", ukrainianName: "Троянда", type: .flower,
            defaultWateringDays: 4,
            varieties: ["Чайно-гібридна", "Плетиста", "Флорібунда", "Мініатюрна"]
        ),
        PlantSpecies(
            name: "Tulip", ukrainianName: "Тюльпан", type: .flower,
            defaultWateringDays: 5,
            varieties: ["Простий ранній", "Махровий", "Лілієцвітний", "Тріумф"]
        ),
        PlantSpecies(
            name: "Marigold", ukrainianName: "Чорнобривці", type: .flower,
            defaultWateringDays: 4,
            varieties: ["Відхилені", "Прямостоячі", "Тонколисті"]
        ),
        PlantSpecies(
            name: "Peony", ukrainianName: "Півонія", type: .flower,
            defaultWateringDays: 5,
            varieties: ["Травʼяниста", "Деревовидна", "Сара Бернар"]
        ),
        PlantSpecies(
            name: "Lavender", ukrainianName: "Лаванда", type: .flower,
            defaultWateringDays: 7,
            varieties: ["Вузьколиста", "Широколиста", "Мунстед"]
        ),
        PlantSpecies(
            name: "Chrysanthemum", ukrainianName: "Хризантема", type: .flower,
            defaultWateringDays: 4,
            varieties: ["Кулясті", "Корейська", "Мультифлора"]
        ),
    ]

    // MARK: - Succulents (Сукуленти)
    static let succulents: [PlantSpecies] = [
        PlantSpecies(
            name: "Aloe Vera", ukrainianName: "Алое", type: .succulent,
            defaultWateringDays: 10,
            varieties: ["Справжнє", "Деревовидне", "Строкате"]
        ),
        PlantSpecies(
            name: "Echeveria", ukrainianName: "Ехеверія", type: .succulent,
            defaultWateringDays: 12,
            varieties: ["Елегантна", "Агавовидна", "Перлина Нюрнберга"]
        ),
        PlantSpecies(
            name: "Cactus", ukrainianName: "Кактус", type: .succulent,
            defaultWateringDays: 14,
            varieties: ["Маммілярія", "Ехінокактус", "Опунція"]
        ),
    ]

    // MARK: - Forest Trees (Лісові дерева)
    static let forestTrees: [PlantSpecies] = [
        PlantSpecies(
            name: "Oak", ukrainianName: "Дуб", type: .forestTree,
            defaultWateringDays: 14,
            varieties: ["Звичайний", "Червоний", "Скельний", "Болотний"]
        ),
        PlantSpecies(
            name: "Birch", ukrainianName: "Береза", type: .forestTree,
            defaultWateringDays: 10,
            varieties: ["Повисла", "Пухнаста", "Карликова"]
        ),
        PlantSpecies(
            name: "Pine", ukrainianName: "Сосна", type: .forestTree,
            defaultWateringDays: 14,
            varieties: ["Звичайна", "Кримська", "Гірська", "Веймутова"]
        ),
        PlantSpecies(
            name: "Linden", ukrainianName: "Липа", type: .forestTree,
            defaultWateringDays: 12,
            varieties: ["Серцелиста", "Дрібнолиста", "Європейська"]
        ),
        PlantSpecies(
            name: "Beech", ukrainianName: "Бук", type: .forestTree,
            defaultWateringDays: 14,
            varieties: ["Лісовий", "Східний", "Пурпурний"]
        ),
        PlantSpecies(
            name: "Maple", ukrainianName: "Клен", type: .forestTree,
            defaultWateringDays: 12,
            varieties: ["Гостролистий", "Явір", "Татарський", "Цукровий"]
        ),
        PlantSpecies(
            name: "Spruce", ukrainianName: "Ялина", type: .forestTree,
            defaultWateringDays: 14,
            varieties: ["Європейська", "Блакитна", "Сербська", "Коніка"]
        ),
        PlantSpecies(
            name: "Ash", ukrainianName: "Ясен", type: .forestTree,
            defaultWateringDays: 12,
            varieties: ["Звичайний", "Вузьколистий", "Пенсильванський"]
        ),
        PlantSpecies(
            name: "Hornbeam", ukrainianName: "Граб", type: .forestTree,
            defaultWateringDays: 12,
            varieties: ["Звичайний", "Східний"]
        ),
        PlantSpecies(
            name: "Alder", ukrainianName: "Вільха", type: .forestTree,
            defaultWateringDays: 10,
            varieties: ["Чорна", "Сіра"]
        ),
    ]

    // MARK: - Fruit Trees (Плодові дерева)
    static let fruitTrees: [PlantSpecies] = [
        PlantSpecies(
            name: "Cherry", ukrainianName: "Вишня", type: .fruitTree,
            defaultWateringDays: 7,
            varieties: ["Шпанка", "Любська", "Гріот київський", "Молодіжна", "Тургенівка"]
        ),
        PlantSpecies(
            name: "Merry Cherry", ukrainianName: "Черешня", type: .fruitTree,
            defaultWateringDays: 7,
            varieties: ["Великоплідна", "Валерій Чкалов", "Дрогана жовта", "Регіна", "Ревна"]
        ),
        PlantSpecies(
            name: "Apple", ukrainianName: "Яблуня", type: .fruitTree,
            defaultWateringDays: 7,
            varieties: ["Антонівка", "Голден Делішес", "Семеренко", "Ренет Симиренка", "Гала", "Фуджі"]
        ),
        PlantSpecies(
            name: "Pear", ukrainianName: "Груша", type: .fruitTree,
            defaultWateringDays: 7,
            varieties: ["Вільямс", "Конференція", "Ліщина", "Бере Боск", "Ноябрська"]
        ),
        PlantSpecies(
            name: "Plum", ukrainianName: "Слива", type: .fruitTree,
            defaultWateringDays: 7,
            varieties: ["Угорка", "Ренклод", "Синя птиця", "Стенлі", "Президент"]
        ),
        PlantSpecies(
            name: "Apricot", ukrainianName: "Абрикос", type: .fruitTree,
            defaultWateringDays: 10,
            varieties: ["Краснощокий", "Ананасний", "Мелітопольський ранній", "Шалах"]
        ),
        PlantSpecies(
            name: "Peach", ukrainianName: "Персик", type: .fruitTree,
            defaultWateringDays: 7,
            varieties: ["Київський ранній", "Редхейвен", "Донецький жовтий", "Золотий ювілей", "Білий лебідь"]
        ),
        PlantSpecies(
            name: "Walnut", ukrainianName: "Горіх", type: .fruitTree,
            defaultWateringDays: 14,
            varieties: ["Волоський", "Ідеал", "Буковинський", "Великоплідний"]
        ),
        PlantSpecies(
            name: "Mulberry", ukrainianName: "Шовковиця", type: .fruitTree,
            defaultWateringDays: 10,
            varieties: ["Біла", "Чорна", "Червона"]
        ),
        PlantSpecies(
            name: "Quince", ukrainianName: "Айва", type: .fruitTree,
            defaultWateringDays: 10,
            varieties: ["Звичайна", "Японська", "Ананасна"]
        ),
    ]

    // MARK: - Bushes (Кущі)
    static let bushes: [PlantSpecies] = [
        PlantSpecies(
            name: "Currant", ukrainianName: "Смородина", type: .bush,
            defaultWateringDays: 5,
            varieties: ["Чорна Перлина", "Червона", "Біла", "Ядреная", "Добриня"]
        ),
        PlantSpecies(
            name: "Raspberry", ukrainianName: "Малина", type: .bush,
            defaultWateringDays: 4,
            varieties: ["Ремонтантна", "Полана", "Гусар", "Геракл", "Жовтий гігант"]
        ),
        PlantSpecies(
            name: "Strawberry", ukrainianName: "Полуниця", type: .bush,
            defaultWateringDays: 3,
            varieties: ["Вікторія", "Полка", "Хоней", "Альбіон", "Елізабет"]
        ),
        PlantSpecies(
            name: "Blueberry", ukrainianName: "Лохина", type: .bush,
            defaultWateringDays: 4,
            varieties: ["Блюкроп", "Патріот", "Дюк", "Спартан", "Нортланд"]
        ),
        PlantSpecies(
            name: "Gooseberry", ukrainianName: "Аґрус", type: .bush,
            defaultWateringDays: 5,
            varieties: ["Машенька", "Фінік", "Чорний негус", "Малахіт"]
        ),
        PlantSpecies(
            name: "Blackberry", ukrainianName: "Ожина", type: .bush,
            defaultWateringDays: 4,
            varieties: ["Торнфрі", "Блек Сатін", "Натчез", "Честер"]
        ),
        PlantSpecies(
            name: "Sea Buckthorn", ukrainianName: "Обліпиха", type: .bush,
            defaultWateringDays: 7,
            varieties: ["Чуйська", "Золотий початок", "Московська красуня"]
        ),
    ]

    // MARK: - All Species
    // One big list combining everything — useful for searching
    static let all: [PlantSpecies] = herbs + vegetables + flowers + succulents + forestTrees + fruitTrees + bushes

    // MARK: - Helper: Get species by type
    // Returns only plants of a specific type — useful for filtered views
    static func species(for type: PlantType) -> [PlantSpecies] {
        switch type {
        case .herb:       return herbs
        case .vegetable:  return vegetables
        case .flower:     return flowers
        case .succulent:  return succulents
        case .forestTree: return forestTrees
        case .fruitTree:  return fruitTrees
        case .bush:       return bushes
        }
    }
}
