import SwiftUI

// MARK: - Plant Detail View
// This screen opens when you tap a plant in the list.
// It shows all the info about that plant and lets you water it.
//
// Key concept: @Binding
// The plant list OWNS the data. This detail view BORROWS it via @Binding.
// When you tap "Water Now" here, the change flows back to the list automatically.
// Think of it like editing a shared Google Doc — both screens see the same data.

struct PlantDetailView: View {

    // @Binding = "I don't own this data, but I can read AND change it"
    // Changes here automatically update the plant list too.
    @Binding var plant: Plant

    // Access the store so we can save changes to disk
    @Environment(PlantStore.self) private var store

    // Lets us go back to the list after deleting
    @Environment(\.dismiss) private var dismiss

    // Controls the delete confirmation alert
    @State private var showingDeleteAlert = false

    // Controls the "Log Activity" form
    @State private var showingAddActivity = false

    // Controls the "Edit Plant" form
    @State private var showingEditPlant = false

    // Used to format dates nicely (e.g. "April 3, 2026" instead of raw date)
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long     // "April 3, 2026"
        formatter.timeStyle = .none     // don't show time
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // -- Header: Big icon + name --
                headerSection

                // -- Watering Status Card --
                wateringCard

                // -- Plant Info Card --
                infoCard

                // -- Care Intelligence (the smart part!) --
                if let species = PlantCatalog.find(name: plant.name) {
                    TreeIntelligenceView(
                        species: species,
                        plantAge: plant.age
                    )
                }

                // -- Quick Actions (Water + Log Activity) --
                quickActionsSection

                // -- Activity Journal --
                activityJournalSection

                // -- Delete Button --
                deleteButton
            }
            .padding()
        }
        .navigationTitle(plant.name)
        .navigationBarTitleDisplayMode(.inline)
        // Edit button in the top-right corner of the navigation bar
        // This is a standard iOS pattern — most detail screens have an Edit button
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditPlant = true
                } label: {
                    Text("Edit")
                }
            }
        }
        // Sheet for editing plant details
        .sheet(isPresented: $showingEditPlant) {
            EditPlantView(plant: plant) { updatedPlant in
                // Apply the changes to our @Binding plant
                // This automatically updates the plant list too!
                plant = updatedPlant
                store.update(updatedPlant)
            }
        }
        // Confirmation alert before deleting — prevents accidental deletion
        // Sheet for logging a new activity
        .sheet(isPresented: $showingAddActivity) {
            AddActivityView { activity in
                plant.activities.append(activity)
                // If it's a watering activity, also update lastWatered
                if activity.type == .watered {
                    plant.lastWatered = activity.date
                }
                store.save()
            }
        }
        .alert("Delete Plant", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                store.delete(id: plant.id)
                dismiss() // Go back to the list
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove \(plant.name) from your garden? This can't be undone.")
        }
    }

    // MARK: - Header Section
    // A big, eye-catching header with the plant type icon and name.

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Plant photo — tappable to take a new photo or pick from library
            // If no photo exists, shows a camera placeholder
            PlantPhotoHeader(
                photoID: plant.photoID,
                size: 120
            ) { newPhotoID in
                // Delete the old photo file if there was one
                if let oldID = plant.photoID {
                    PhotoManager.shared.delete(id: oldID)
                }
                plant.photoID = newPhotoID
                store.save()
            }

            // Plant name
            Text(plant.name)
                .font(.title)
                .fontWeight(.bold)

            // Variety (if available)
            if let variety = plant.variety {
                Text(variety)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Type + age badges
            HStack(spacing: 8) {
                Text(plant.type.localizedName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(plant.type.color.opacity(0.15))
                    .foregroundStyle(plant.type.color)
                    .clipShape(Capsule())

                if let ageLabel = plant.ageLabel {
                    Text(ageLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Watering Card
    // Shows watering status: when last watered, when next watering is due,
    // and a clear visual indicator (needs water vs. all good).

    private var wateringCard: some View {
        VStack(spacing: 16) {
            // Card header
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                Text("Watering")
                    .font(.headline)
                Spacer()

                // Status badge
                if plant.needsWatering {
                    Text("Needs Water!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                } else {
                    Text("All Good")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
            }

            Divider()

            // Watering details rows
            detailRow(
                icon: "clock.arrow.circlepath",
                label: "Frequency",
                value: "Every \(plant.wateringFrequencyDays) days"
            )

            detailRow(
                icon: "calendar.badge.clock",
                label: "Last Watered",
                value: lastWateredText
            )

            detailRow(
                icon: "calendar",
                label: "Next Watering",
                value: nextWateringText
            )
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Info Card
    // General info about the plant — when it was added, etc.

    private var infoCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.secondary)
                Text("Plant Info")
                    .font(.headline)
                Spacer()
            }

            Divider()

            detailRow(
                icon: "leaf.fill",
                label: "Type",
                value: plant.type.localizedName
            )

            detailRow(
                icon: "calendar.badge.plus",
                label: "Added to Garden",
                value: dateFormatter.string(from: plant.dateAdded)
            )

            if let variety = plant.variety {
                detailRow(
                    icon: "tag.fill",
                    label: "Variety",
                    value: variety
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Quick Actions Section
    // Two buttons side by side: "Water Now" and "Log Activity"

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            // Water Now button
            Button {
                plant.lastWatered = Date()
                // Also log it as an activity in the journal, tagged with active family member
                let activity = CareActivity(
                    type: .watered,
                    date: Date(),
                    note: nil,
                    memberID: FamilyManager.shared.activeMember?.id
                )
                plant.activities.append(activity)
                // Use store.water() instead of store.save() so the
                // watering notification gets rescheduled automatically!
                store.water(id: plant.id)
            } label: {
                Label("Water Now", systemImage: "drop.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(plant.needsWatering ? .blue : .blue.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Log Activity button — opens the activity form
            Button {
                showingAddActivity = true
            } label: {
                Label("Log Activity", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Activity Journal Section
    // Shows the timeline of all activities done to this plant.

    private var activityJournalSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                Text("Activity Journal")
                    .font(.headline)
                Spacer()

                if !plant.activities.isEmpty {
                    Text("\(plant.activities.count) entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            ActivityTimelineView(activities: plant.activities)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Delete Button
    // A red button at the bottom to remove this plant from your garden.
    // Shows a confirmation alert first so you don't delete by accident.

    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Label("Remove from Garden", systemImage: "trash")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red.opacity(0.1))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 4)
    }

    // MARK: - Helper: Detail Row
    // A reusable row used inside cards: icon + label on left, value on right.
    // We use this many times above — keeps the code DRY (Don't Repeat Yourself).

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Computed Text Values

    private var lastWateredText: String {
        guard let lastWatered = plant.lastWatered else {
            return "Never"
        }
        // Show how many days ago it was watered
        let days = Calendar.current.dateComponents([.day], from: lastWatered, to: Date()).day ?? 0
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else {
            return "\(days) days ago"
        }
    }

    private var nextWateringText: String {
        guard let nextDate = plant.nextWateringDate else {
            return "Water now!"
        }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
        if days < 0 {
            return "Overdue by \(abs(days)) days!"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "In \(days) days"
        }
    }
}

// MARK: - Preview
// @State in preview creates temporary data so we can see the screen.

#Preview("Needs Watering") {
    NavigationStack {
        PlantDetailView(plant: .constant(Plant.samples[1]))
    }
}

#Preview("Recently Watered") {
    NavigationStack {
        PlantDetailView(plant: .constant(Plant.samples[2]))
    }
}
