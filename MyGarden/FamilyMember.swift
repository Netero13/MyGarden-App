import Foundation
import SwiftUI

// MARK: - Family Member
// Represents one person in the family who uses the garden.
// Each member has a name, a role (Dad/Mom/Son/Daughter), and an emoji avatar.
//
// When someone logs an activity (watered, pruned, etc.), their member ID
// is saved with that activity — so the family can see WHO did WHAT.
//
// Key concept: Codable
// Like Plant and CareActivity, this is Codable so it can be saved as JSON.

struct FamilyMember: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String          // e.g. "Ivan", "Maria"
    var role: FamilyRole      // Dad, Mom, Son, Daughter
    var emoji: String         // avatar emoji, e.g. "👨", "👩", "👦", "👧"
}

// MARK: - Family Role
// The role/position in the family. All roles have EQUAL rights —
// anyone can water, prune, add, or delete plants.
// The role is just for display (avatar, color) so you can tell
// family members apart at a glance.

enum FamilyRole: String, Codable, CaseIterable, Identifiable {
    case dad = "Dad"
    case mom = "Mom"
    case son = "Son"
    case daughter = "Daughter"
    case grandpa = "Grandpa"
    case grandma = "Grandma"
    case other = "Other"

    var id: String { rawValue }

    // Localized display name
    var localizedName: String {
        NSLocalizedString(rawValue, comment: "")
    }

    // Default emoji for each role
    var defaultEmoji: String {
        switch self {
        case .dad:       return "👨"
        case .mom:       return "👩"
        case .son:       return "👦"
        case .daughter:  return "👧"
        case .grandpa:   return "👴"
        case .grandma:   return "👵"
        case .other:     return "🧑"
        }
    }

    // Color for each role (used in activity feed, badges, etc.)
    var color: Color {
        switch self {
        case .dad:       return .blue
        case .mom:       return .pink
        case .son:       return .cyan
        case .daughter:  return .purple
        case .grandpa:   return .brown
        case .grandma:   return .orange
        case .other:     return .gray
        }
    }
}
