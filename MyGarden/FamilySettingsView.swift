import SwiftUI

// MARK: - Family Settings View
// Manage family members: add, remove, edit, and switch the active member.
// Accessible from the Settings tab.
//
// Each member shows their emoji avatar and name.
// The active member (currently "logged in") has a checkmark.

struct FamilySettingsView: View {

    // We read directly from the singleton
    private var familyManager = FamilyManager.shared

    // State for the "Add Member" sheet
    @State private var showingAddMember = false

    // State for editing an existing member
    @State private var editingMember: FamilyMember?

    var body: some View {
        List {
            // -- Current active member --
            if let active = familyManager.activeMember {
                Section {
                    HStack(spacing: 14) {
                        Text(active.emoji)
                            .font(.system(size: 40))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(active.name)
                                .font(.headline)
                            Text("Currently active")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Active Member")
                } footer: {
                    Text("Activities you log will be tagged with this person's name.")
                }
            }

            // -- All family members --
            Section {
                if familyManager.members.isEmpty {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundStyle(.secondary)
                        Text("No family members yet")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(familyManager.members) { member in
                        memberRow(member)
                    }
                    .onDelete { offsets in
                        for offset in offsets {
                            familyManager.remove(id: familyManager.members[offset].id)
                        }
                    }
                }

                // Add member button
                Button {
                    showingAddMember = true
                } label: {
                    Label("Add Family Member", systemImage: "person.badge.plus")
                }
            } header: {
                Text("Family Members")
            } footer: {
                Text("Everyone has equal rights — anyone can water, add, or edit plants. Swipe left to remove a member.")
            }
        }
        .navigationTitle("Family")
        .sheet(isPresented: $showingAddMember) {
            AddFamilyMemberView { member in
                familyManager.add(member)
            }
        }
        .sheet(item: $editingMember) { member in
            EditFamilyMemberView(member: member) { updated in
                familyManager.update(updated)
            }
        }
    }

    // MARK: - Member Row

    private func memberRow(_ member: FamilyMember) -> some View {
        Button {
            // Tap to switch active member
            familyManager.setActive(member)
        } label: {
            HStack(spacing: 12) {
                // Emoji avatar
                Text(member.emoji)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(.green.opacity(0.15))
                    .clipShape(Circle())

                // Name
                Text(member.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                // Edit button
                Button {
                    editingMember = member
                } label: {
                    Image(systemName: "pencil.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                // Active checkmark
                if member.id == familyManager.activeMemberID {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Family Member View
// A simple form to add a new family member: just name + emoji avatar.

struct AddFamilyMemberView: View {

    var onAdd: (FamilyMember) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var emoji: String = "🧑‍🌾"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Who are you adding?")
                }

                Section {
                    // Emoji picker — a grid of common emoji options
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                        ForEach(emojiOptions, id: \.self) { e in
                            Button {
                                emoji = e
                            } label: {
                                Text(e)
                                    .font(.title)
                                    .frame(width: 46, height: 46)
                                    .background(emoji == e ? .green.opacity(0.2) : .clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(emoji == e ? .green : .clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Choose Avatar")
                }

                // Preview
                Section {
                    HStack(spacing: 12) {
                        Text(emoji)
                            .font(.system(size: 36))
                            .frame(width: 50, height: 50)
                            .background(.green.opacity(0.15))
                            .clipShape(Circle())

                        Text(name.isEmpty ? "Name" : name)
                            .font(.headline)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                    }
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let member = FamilyMember(
                            name: name.trimmingCharacters(in: .whitespaces),
                            emoji: emoji
                        )
                        onAdd(member)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }

    // Common emoji options for avatars
    private var emojiOptions: [String] {
        ["🧑‍🌾", "👨‍🌾", "👩‍🌾", "👨", "👩", "👦", "👧", "👴", "👵", "🧑",
         "👱", "🌻", "🌿", "🌱", "🪴", "🍀"]
    }
}

// MARK: - Edit Family Member View

struct EditFamilyMemberView: View {

    let member: FamilyMember
    var onSave: (FamilyMember) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var emoji: String = "🧑‍🌾"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                        ForEach(emojiOptions, id: \.self) { e in
                            Button {
                                emoji = e
                            } label: {
                                Text(e)
                                    .font(.title)
                                    .frame(width: 46, height: 46)
                                    .background(emoji == e ? .green.opacity(0.2) : .clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(emoji == e ? .green : .clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Avatar")
                }
            }
            .navigationTitle("Edit Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = member
                        updated.name = name.trimmingCharacters(in: .whitespaces)
                        updated.emoji = emoji
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                name = member.name
                emoji = member.emoji
            }
        }
    }

    private var emojiOptions: [String] {
        ["🧑‍🌾", "👨‍🌾", "👩‍🌾", "👨", "👩", "👦", "👧", "👴", "👵", "🧑",
         "👱", "🌻", "🌿", "🌱", "🪴", "🍀"]
    }
}

#Preview {
    NavigationStack {
        FamilySettingsView()
    }
}
