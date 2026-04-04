import Foundation
import SwiftUI

// MARK: - Activity Status
// Every activity is either "Planned" (recommended/scheduled, not done yet)
// or "Done" (actually completed). This lets the app track what's upcoming
// AND what's been accomplished — like a to-do list for your garden.

enum ActivityStatus: String, Codable {
    case planned = "Planned"
    case done = "Done"

    var localizedName: String {
        NSLocalizedString(rawValue, comment: "")
    }
}

// MARK: - Care Activity
// A single log entry: "I did THIS to THIS plant on THIS date."
// Think of it like a diary entry for your plant.
//
// Activities can be:
// - Auto-planned: CareAction Engine creates them at the start of each month from TreeIntelligence
// - Manually planned: User creates them via "Log Activity" with status = .planned
// - Done: Either completed by the user, or logged directly as done
//
// Example: { type: .pruned, date: Apr 3, status: .done, note: "removed dead branches" }

struct CareActivity: Identifiable, Codable {
    var id = UUID()
    var type: CareType              // what to do / what was done
    var date: Date                  // when it was planned or done
    var note: String?               // optional details
    var photoID: String?            // optional photo (stored as a file)
    var memberName: String?         // WHO did this activity
    var status: ActivityStatus      // planned or done
    var completionDate: Date?       // when a planned activity was marked done (nil for direct "done" logs)

    // Backward compatibility: old JSON didn't have "status" or "completionDate".
    // Old activities default to .done (they were always logged after completion).
    enum CodingKeys: String, CodingKey {
        case id, type, date, note, photoID, memberName, status, completionDate
    }

    init(
        id: UUID = UUID(),
        type: CareType,
        date: Date,
        note: String? = nil,
        photoID: String? = nil,
        memberName: String? = nil,
        status: ActivityStatus = .done,
        completionDate: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.date = date
        self.note = note
        self.photoID = photoID
        self.memberName = memberName
        self.status = status
        self.completionDate = completionDate
    }

    // Custom decoder — old JSON won't have "status" or "completionDate",
    // so we default them gracefully. This prevents crashes when loading old data.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        type = try c.decode(CareType.self, forKey: .type)
        date = try c.decode(Date.self, forKey: .date)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        photoID = try c.decodeIfPresent(String.self, forKey: .photoID)
        memberName = try c.decodeIfPresent(String.self, forKey: .memberName)
        status = try c.decodeIfPresent(ActivityStatus.self, forKey: .status) ?? .done
        completionDate = try c.decodeIfPresent(Date.self, forKey: .completionDate)
    }
}

// MARK: - Care Type
// All the activities you can do with a plant.
// Each has a label, icon, and color for the UI.

enum CareType: String, Codable, CaseIterable, Identifiable {
    case watered = "Watered"
    case pruned = "Pruned"
    case fertilized = "Fertilized"
    case pestControl = "Pest Control"
    case diseaseControl = "Disease Control"  // NEW: separate from pestControl
    case planted = "Planted"
    case transplanted = "Transplanted"
    case weeded = "Weeded"
    case harvested = "Harvested"
    case winterized = "Winterized"
    case note = "Note"

    var id: String { rawValue }

    // Localized display name — looks up the rawValue in Localizable.strings
    // This is what the user sees. rawValue stays in English for code/data.
    var localizedName: String {
        NSLocalizedString(rawValue, comment: "")
    }

    // SF Symbol icon for each activity
    var icon: String {
        switch self {
        case .watered:        return "drop.fill"
        case .pruned:         return "scissors"
        case .fertilized:     return "leaf.arrow.circlepath"
        case .pestControl:    return "ant.fill"
        case .diseaseControl: return "allergens"
        case .planted:        return "arrow.down.to.line"
        case .transplanted:   return "arrow.left.arrow.right"
        case .weeded:         return "trash.fill"
        case .harvested:      return "basket.fill"
        case .winterized:     return "snowflake"
        case .note:           return "note.text"
        }
    }

    // Color for each activity
    var color: Color {
        switch self {
        case .watered:        return .blue
        case .pruned:         return .orange
        case .fertilized:     return .green
        case .pestControl:    return .red
        case .diseaseControl: return .purple
        case .planted:        return .brown
        case .transplanted:   return .purple
        case .weeded:         return .gray
        case .harvested:      return .yellow
        case .winterized:     return .cyan
        case .note:           return .secondary
        }
    }
}
