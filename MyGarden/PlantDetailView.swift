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

                // -- Weather Intelligence Alerts --
                weatherAlertsCard

                // -- Watering Status Card --
                wateringCard

                // -- Plant Info Card --
                infoCard

                // -- Care Intelligence (the smart part!) --
                if let species = TreeEncyclopedia.find(name: plant.name) {
                    TreeIntelligenceView(
                        species: species,
                        plantAge: plant.age
                    )
                }

                // -- Care This Month (contextual quick actions) --
                careThisMonthActions

                // -- Quick Actions (Water + Log Activity) --
                quickActionsSection

                // -- Care Status Card (last-done dates) --
                careStatusCard

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
                    Text(NSLocalizedString("Edit", comment: ""))
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
        .alert(NSLocalizedString("Delete Plant", comment: ""), isPresented: $showingDeleteAlert) {
            Button(NSLocalizedString("Delete", comment: ""), role: .destructive) {
                store.delete(id: plant.id)
                dismiss() // Go back to the list
            }
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) { }
        } message: {
            Text(String(format: NSLocalizedString("Are you sure you want to remove %@ from your garden? This can't be undone.", comment: ""), plant.name))
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

                Text(plant.ageLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.15))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
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
                Text(NSLocalizedString("Watering", comment: ""))
                    .font(.headline)
                Spacer()

                // Weather-smart watering badge (Phase 2)
                if let weather = WeatherManager.shared.currentWeather {
                    let adjustment = WeatherIntelligence.wateringAdjustment(for: plant, weather: weather)
                    if adjustment != .normal {
                        HStack(spacing: 4) {
                            Image(systemName: adjustment.icon)
                                .font(.caption2)
                            Text(adjustment.localizedLabel)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(adjustment.color.opacity(0.15))
                        .foregroundStyle(adjustment.color)
                        .clipShape(Capsule())
                    }
                }

                // Status badge
                if plant.needsWatering {
                    Text(NSLocalizedString("Needs Water!", comment: ""))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                } else {
                    Text(NSLocalizedString("All Good", comment: ""))
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
                label: NSLocalizedString("Frequency", comment: ""),
                value: String(format: NSLocalizedString("Every %lld days", comment: ""), plant.wateringFrequencyDays)
            )

            detailRow(
                icon: "calendar.badge.clock",
                label: NSLocalizedString("Last Watered", comment: ""),
                value: lastWateredText
            )

            detailRow(
                icon: "calendar",
                label: NSLocalizedString("Next Watering", comment: ""),
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
                Text(NSLocalizedString("Plant Info", comment: ""))
                    .font(.headline)
                Spacer()
            }

            Divider()

            detailRow(
                icon: "leaf.fill",
                label: NSLocalizedString("Type", comment: ""),
                value: plant.type.localizedName
            )

            detailRow(
                icon: "calendar.badge.plus",
                label: NSLocalizedString("Added to Garden", comment: ""),
                value: dateFormatter.string(from: plant.dateAdded)
            )

            if let variety = plant.variety {
                detailRow(
                    icon: "tag.fill",
                    label: NSLocalizedString("Variety", comment: ""),
                    value: variety
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Care This Month Actions
    // Shows contextual quick-action buttons for care tasks due THIS month.
    // Only appears when TreeIntelligence says something needs doing AND it
    // hasn't been done yet. Tap a button → task logged + button disappears.

    @ViewBuilder
    private var careThisMonthActions: some View {
        let actions = pendingCareActions
        if !actions.isEmpty {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.orange)
                    Text(NSLocalizedString("Care Due This Month", comment: ""))
                        .font(.headline)
                    Spacer()
                }

                // Each action is tappable — opens the intelligence detail page
                ForEach(actions, id: \.self) { action in
                    if let species = TreeEncyclopedia.find(name: plant.name) {
                        NavigationLink {
                            CareActionDetailView(
                                plant: plant,
                                action: action,
                                species: species
                            )
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: action.icon)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .frame(width: 32, height: 32)
                                    .background(action.color.gradient)
                                    .clipShape(Circle())

                                Text(action.localizedLabel)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(action.color)

                                Spacer()

                                // Done button (stops navigation propagation)
                                Button {
                                    performCareAction(action)
                                } label: {
                                    Image(systemName: "checkmark")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(6)
                                        .background(action.color)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(10)
                            .background(action.color.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // Which care actions are due this month and NOT yet done
    private var pendingCareActions: [CareAction] {
        guard let species = TreeEncyclopedia.find(name: plant.name) else { return [] }
        let intel = species.intelligence
        var actions: [CareAction] = []

        if intel.shouldPruneThisMonth() && !plant.wasDoneThisMonth(.pruned) {
            actions.append(.prune)
        }
        if intel.shouldFertilizeThisMonth() && !plant.wasDoneThisMonth(.fertilized) {
            actions.append(.fertilize)
        }
        if intel.isHarvestTime() && !plant.wasDoneThisMonth(.harvested) {
            actions.append(.harvest)
        }
        if intel.shouldTreatPestsThisMonth() && !plant.wasDoneThisMonth(.pestControl) {
            actions.append(.pestTreatment)
        }
        if intel.shouldTreatDiseasesThisMonth() && !plant.wasDoneThisMonth(.diseaseControl) {
            actions.append(.diseaseTreatment)
        }

        return actions
    }

    // Call the matching store method for each action
    private func performCareAction(_ action: CareAction) {
        switch action {
        case .prune:            store.prune(id: plant.id)
        case .fertilize:        store.fertilize(id: plant.id)
        case .harvest:          store.harvest(id: plant.id)
        case .pestTreatment:    store.treatPests(id: plant.id)
        case .diseaseTreatment: store.treatDiseases(id: plant.id)
        }
    }

    // MARK: - Care Status Card
    // Shows when each care type was last performed — a quick at-a-glance view.
    // Only shows care types relevant to this plant species.

    @ViewBuilder
    private var careStatusCard: some View {
        let rows = careStatusRows
        if !rows.isEmpty {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "list.clipboard")
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString("Care Status", comment: ""))
                        .font(.headline)
                    Spacer()
                }

                Divider()

                ForEach(rows, id: \.label) { row in
                    HStack {
                        Image(systemName: row.icon)
                            .font(.caption)
                            .foregroundStyle(row.color)
                            .frame(width: 20)

                        Text(row.label)
                            .font(.subheadline)

                        Spacer()

                        if let date = row.date {
                            Text(formatCareDate(date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(NSLocalizedString("Not yet", comment: ""))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private struct CareStatusRow: Hashable {
        let icon: String
        let label: String
        let color: Color
        let date: Date?
    }

    // Only include care types that this species actually uses
    private var careStatusRows: [CareStatusRow] {
        guard let species = TreeEncyclopedia.find(name: plant.name) else { return [] }
        let intel = species.intelligence
        var rows: [CareStatusRow] = []

        if !intel.pruningMonths.isEmpty {
            rows.append(CareStatusRow(icon: "scissors", label: NSLocalizedString("Pruned", comment: ""), color: .orange, date: plant.lastPruned))
        }
        if !intel.fertilizerMonths.isEmpty {
            rows.append(CareStatusRow(icon: "leaf.arrow.circlepath", label: NSLocalizedString("Fertilized", comment: ""), color: .green, date: plant.lastFertilized))
        }
        if intel.harvestMonths != nil {
            rows.append(CareStatusRow(icon: "basket.fill", label: NSLocalizedString("Harvested", comment: ""), color: .yellow, date: plant.lastHarvested))
        }
        if !intel.pestTreatmentMonths.isEmpty {
            rows.append(CareStatusRow(icon: "ant.fill", label: NSLocalizedString("Pest Treated", comment: ""), color: .red, date: plant.lastTreatedPests))
        }
        if !intel.diseaseTreatmentMonths.isEmpty {
            rows.append(CareStatusRow(icon: "allergens", label: NSLocalizedString("Disease Treated", comment: ""), color: .purple, date: plant.lastTreatedDiseases))
        }

        return rows
    }

    private func formatCareDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Quick Actions Section
    // Two buttons side by side: "Water Now" and "Log Activity"

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            // Water Now button
            Button {
                // store.water() handles everything:
                // sets lastWatered, logs the activity, saves, reschedules notification
                store.water(id: plant.id)
            } label: {
                Label(NSLocalizedString("Water Now", comment: ""), systemImage: "drop.fill")
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
                Label(NSLocalizedString("Log Activity", comment: ""), systemImage: "plus.circle.fill")
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
                Text(NSLocalizedString("Activity Journal", comment: ""))
                    .font(.headline)
                Spacer()

                if !plant.activities.isEmpty {
                    Text(String(format: NSLocalizedString("%lld entries", comment: ""), plant.activities.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            ActivityTimelineView(activities: plant.activities, plant: plant)
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
            Label(NSLocalizedString("Remove from Garden", comment: ""), systemImage: "trash")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red.opacity(0.1))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 4)
    }

    // MARK: - Weather Alerts Card (Phase 2)
    // Shows smart, plant-specific weather recommendations.
    // Example: "Skip watering — it rained 8mm" or "Frost tonight — protect your cherry!"
    // Only appears when weather data is available AND there are tips to show.

    @ViewBuilder
    private var weatherAlertsCard: some View {
        if let weather = WeatherManager.shared.currentWeather {
            let tips = WeatherIntelligence.tips(for: plant, weather: weather)
            if !tips.isEmpty {
                VStack(spacing: 12) {
                    // Card header
                    HStack {
                        Image(systemName: "brain.head.profile.fill")
                            .foregroundStyle(.purple)
                        Text(NSLocalizedString("Weather Intelligence", comment: ""))
                            .font(.headline)
                        Spacer()

                        // Show count badge
                        Text("\(tips.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.purple.opacity(0.15))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }

                    Divider()

                    // Each tip as a row
                    ForEach(tips) { tip in
                        HStack(alignment: .top, spacing: 12) {
                            // Priority-colored icon
                            ZStack {
                                Circle()
                                    .fill(tip.color.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: tip.icon)
                                    .font(.callout)
                                    .foregroundStyle(tip.color)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(tip.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    if tip.priority == .urgent {
                                        Text(NSLocalizedString("URGENT", comment: ""))
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(.red)
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(tip.message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(tips.first?.priority == .urgent ? .red.opacity(0.3) : .purple.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
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
            return NSLocalizedString("Never", comment: "")
        }
        let days = Calendar.current.dateComponents([.day], from: lastWatered, to: Date()).day ?? 0
        if days == 0 {
            return NSLocalizedString("Today", comment: "")
        } else if days == 1 {
            return NSLocalizedString("Yesterday", comment: "")
        } else {
            return String(format: NSLocalizedString("%lld days ago", comment: ""), days)
        }
    }

    private var nextWateringText: String {
        guard let nextDate = plant.nextWateringDate else {
            return NSLocalizedString("Water now!", comment: "")
        }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
        if days < 0 {
            return String(format: NSLocalizedString("Overdue by %lld days!", comment: ""), abs(days))
        } else if days == 0 {
            return NSLocalizedString("Today", comment: "")
        } else if days == 1 {
            return NSLocalizedString("Tomorrow", comment: "")
        } else {
            return String(format: NSLocalizedString("In %lld days", comment: ""), days)
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
