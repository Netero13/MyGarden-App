import Foundation
import SwiftUI

// MARK: - Family Manager
// Manages the family members and tracks who is currently "active" (using the app).
// Think of it like a login system but much simpler — you just tap your avatar
// to switch between family members. No passwords needed.
//
// Data is saved as a separate JSON file (myGarden_family.json), just like
// how PlantStore saves plants to myGarden_plants.json.
//
// Key concept: Singleton + @Observable
// - Singleton: one shared instance (FamilyManager.shared) used everywhere
// - @Observable: SwiftUI automatically updates when members change

@Observable
class FamilyManager {

    // Singleton — one shared instance across the whole app
    static let shared = FamilyManager()

    // All family members
    var members: [FamilyMember] = []

    // The currently active member (who is using the app right now)
    // Stored as UUID in UserDefaults so it persists across app launches
    var activeMemberID: UUID? {
        get {
            guard let string = UserDefaults.standard.string(forKey: "activeMemberID"),
                  let uuid = UUID(uuidString: string) else { return nil }
            return uuid
        }
        set {
            UserDefaults.standard.set(newValue?.uuidString, forKey: "activeMemberID")
        }
    }

    // Convenience: get the active member object
    var activeMember: FamilyMember? {
        guard let id = activeMemberID else { return members.first }
        return members.first { $0.id == id } ?? members.first
    }

    // MARK: - Init

    private init() {
        if let saved = Self.load() {
            members = saved
        }
        // If no active member is set, default to the first one
        if activeMemberID == nil, let first = members.first {
            activeMemberID = first.id
        }
    }

    // MARK: - Add Member

    func add(_ member: FamilyMember) {
        members.append(member)
        // If this is the first member, make them active
        if members.count == 1 {
            activeMemberID = member.id
        }
        save()
    }

    // MARK: - Remove Member

    func remove(id: UUID) {
        members.removeAll { $0.id == id }
        // If we removed the active member, switch to the first remaining
        if activeMemberID == id {
            activeMemberID = members.first?.id
        }
        save()
    }

    // MARK: - Update Member

    func update(_ member: FamilyMember) {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index] = member
            save()
        }
    }

    // MARK: - Switch Active Member

    func setActive(_ member: FamilyMember) {
        activeMemberID = member.id
    }

    // MARK: - Find Member by ID
    // Used to look up who did an activity from the activity's memberID.

    func member(for id: UUID?) -> FamilyMember? {
        guard let id = id else { return nil }
        return members.first { $0.id == id }
    }

    // MARK: - Persistence (Save/Load)

    func save() {
        do {
            let data = try JSONEncoder().encode(members)
            try data.write(to: Self.fileURL)
        } catch {
            print("❌ Failed to save family: \(error)")
        }
    }

    private static func load() -> [FamilyMember]? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([FamilyMember].self, from: data)
        } catch {
            print("❌ Failed to load family: \(error)")
            return nil
        }
    }

    private static var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("myGarden_family.json")
    }
}
