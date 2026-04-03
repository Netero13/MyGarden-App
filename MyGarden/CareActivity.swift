import Foundation
import SwiftUI

// MARK: - Care Activity
// A single log entry: "I did THIS to THIS plant on THIS date."
// Think of it like a diary entry for your plant.
//
// Example: { type: .pruned, date: Apr 3, note: "removed dead branches" }

struct CareActivity: Identifiable, Codable {
    var id = UUID()
    var type: CareType       // what you did (watered, pruned, etc.)
    var date: Date           // when you did it
    var note: String?        // optional details
    var photoID: String?     // optional photo of the activity (stored as a file)
    var memberID: UUID?      // WHO did this activity (nil = unknown / before family feature)
}

// MARK: - Care Type
// All the activities you can do with a plant.
// Each has a label, icon, and color for the UI.

enum CareType: String, Codable, CaseIterable, Identifiable {
    case watered = "Watered"
    case pruned = "Pruned"
    case fertilized = "Fertilized"
    case pestControl = "Pest Control"
    case planted = "Planted"
    case transplanted = "Transplanted"
    case weeded = "Weeded"
    case harvested = "Harvested"
    case winterized = "Winterized"
    case note = "Note"

    var id: String { rawValue }

    // SF Symbol icon for each activity
    var icon: String {
        switch self {
        case .watered:       return "drop.fill"
        case .pruned:        return "scissors"
        case .fertilized:    return "leaf.arrow.circlepath"
        case .pestControl:   return "ant.fill"
        case .planted:       return "arrow.down.to.line"
        case .transplanted:  return "arrow.left.arrow.right"
        case .weeded:        return "trash.fill"
        case .harvested:     return "basket.fill"
        case .winterized:    return "snowflake"
        case .note:          return "note.text"
        }
    }

    // Color for each activity
    var color: Color {
        switch self {
        case .watered:       return .blue
        case .pruned:        return .orange
        case .fertilized:    return .green
        case .pestControl:   return .red
        case .planted:       return .brown
        case .transplanted:  return .purple
        case .weeded:        return .gray
        case .harvested:     return .yellow
        case .winterized:    return .cyan
        case .note:          return .secondary
        }
    }
}
