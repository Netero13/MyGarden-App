import Foundation

// MARK: - Watering Frequency
// Pre-defined watering schedules the user can easily pick from.
// Instead of guessing "how many days?", they see friendly labels like
// "Every day", "Twice a week", "Once a week", etc.
//
// The user picks one of these, and it converts to a number of days.
// They can also choose "Custom" and type their own number.

enum WateringFrequency: String, CaseIterable, Identifiable {
    case daily = "Every day"
    case everyOtherDay = "Every other day"
    case twiceAWeek = "Twice a week"
    case everyThreeDays = "Every 3 days"
    case everyFourDays = "Every 4 days"
    case everyFiveDays = "Every 5 days"
    case onceAWeek = "Once a week"
    case every10Days = "Every 10 days"
    case everyTwoWeeks = "Every 2 weeks"
    case onceAMonth = "Once a month"

    // Identifiable requires an 'id' — we just use the rawValue (the label text)
    var id: String { rawValue }

    // Convert the friendly label to actual number of days
    var days: Int {
        switch self {
        case .daily:          return 1
        case .everyOtherDay:  return 2
        case .twiceAWeek:     return 3
        case .everyThreeDays: return 3
        case .everyFourDays:  return 4
        case .everyFiveDays:  return 5
        case .onceAWeek:      return 7
        case .every10Days:    return 10
        case .everyTwoWeeks:  return 14
        case .onceAMonth:     return 30
        }
    }

    // Reverse: given a number of days, find the closest matching frequency.
    // This is used when loading a plant from the catalog — we convert its
    // defaultWateringDays into the nearest friendly label.
    static func closest(to days: Int) -> WateringFrequency {
        // Find the frequency whose .days is closest to the input
        return WateringFrequency.allCases.min(by: {
            abs($0.days - days) < abs($1.days - days)
        }) ?? .onceAWeek
    }
}
