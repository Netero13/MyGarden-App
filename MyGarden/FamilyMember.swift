import Foundation
import SwiftUI

// MARK: - Family Member
// Represents one person in the family who uses the garden.
// Each member has a name and an emoji avatar.
//
// When someone logs an activity (watered, pruned, etc.), their member ID
// is saved with that activity — so the family can see WHO did WHAT.
//
// Key concept: Codable
// Like Plant and CareActivity, this is Codable so it can be saved as JSON.
// Note: we removed the "role" field (Dad/Mom/etc.) to keep things simple.
// If old data has a "role" key in JSON, Swift's Codable ignores unknown keys
// by default, so existing data will still load fine.

struct FamilyMember: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String          // e.g. "Ivan", "Maria"
    var emoji: String         // avatar emoji, e.g. "👨", "👩", "🧑‍🌾"
}
