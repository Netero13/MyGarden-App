import SwiftUI

// MARK: - Activity Feed View
// A unified timeline showing ALL activities across ALL plants.
// Think of it like a "news feed" for your garden — newest events first.
//
// Features:
// - Filter chips at the top to show only specific activity types
// - Tap any row to open the full ActivityDetailView
// - Can be opened with a pre-set filter (e.g., from dashboard "Prune" card)
//
// You can also filter by activity type (show only watering, only pruning, etc.)

struct ActivityFeedView: View {

    // Access the shared plant store
    @Environment(PlantStore.self) private var store

    // Filter: which activity types to show (nil = show all)
    // Can be set from outside (e.g., dashboard passes .pruned to show only pruning)
    @State var selectedFilter: CareType?

    // Controls the "Plan / Log Activity" sheet
    @State private var showingAddActivity = false

    var body: some View {
        NavigationStack {
            Group {
                if allActivities.isEmpty {
                    // No activities at all — empty state
                    ContentUnavailableView(
                        NSLocalizedString("No Activities Yet", comment: ""),
                        systemImage: "clock.arrow.circlepath",
                        description: Text(NSLocalizedString("Start logging activities on your plants and they'll appear here.", comment: ""))
                    )
                } else if filteredActivities.isEmpty {
                    // Activities exist but none match the filter
                    ContentUnavailableView(
                        NSLocalizedString("No activities match this filter. Try a different one.", comment: ""),
                        systemImage: selectedFilter?.icon ?? "magnifyingglass"
                    )
                } else {
                    // Main list
                    List {
                        // -- Filter chips at the top --
                        Section {
                            filterChips
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        }

                        // Group activities by date (Today, Yesterday, Earlier, etc.)
                        ForEach(groupedByDate.keys.sorted().reversed(), id: \.self) { dateKey in
                            Section {
                                ForEach(groupedByDate[dateKey] ?? []) { entry in
                                    NavigationLink {
                                        ActivityDetailView(activity: entry.activity, plant: entry.plant)
                                    } label: {
                                        activityRow(entry)
                                    }
                                }
                            } header: {
                                Text(dateKey)
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }
            }
            .navigationTitle(filterTitle)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddActivity = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                GlobalAddActivityView()
            }
        }
    }

    // MARK: - Navigation Title
    // Shows the filter name if one is active, otherwise generic title
    private var filterTitle: String {
        if let filter = selectedFilter {
            return filter.localizedName
        }
        return NSLocalizedString("Activity Feed", comment: "")
    }

    // MARK: - Filter Chips
    // Visible horizontal scroll of type buttons — much easier to discover
    // than the old hidden toolbar menu.

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                Button {
                    selectedFilter = nil
                } label: {
                    Text(NSLocalizedString("All", comment: ""))
                        .font(.caption)
                        .fontWeight(selectedFilter == nil ? .bold : .regular)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(selectedFilter == nil ? Color.primary.opacity(0.1) : Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.secondary.opacity(0.3), lineWidth: selectedFilter == nil ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)

                // One chip per type that has activities
                ForEach(availableTypes, id: \.self) { type in
                    Button {
                        if selectedFilter == type {
                            selectedFilter = nil
                        } else {
                            selectedFilter = type
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.caption2)
                            Text(type.localizedName)
                                .font(.caption)
                        }
                        .fontWeight(selectedFilter == type ? .bold : .regular)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(selectedFilter == type ? type.color.opacity(0.15) : .clear)
                        .foregroundStyle(selectedFilter == type ? type.color : .primary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(selectedFilter == type ? type.color.opacity(0.3) : .secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // Which CareTypes have at least one activity
    private var availableTypes: [CareType] {
        let typeSet = Set(allActivities.map(\.activity.type))
        return CareType.allCases.filter { typeSet.contains($0) }
    }

    // MARK: - Activity Row
    // A single entry in the feed showing plant info + activity details.

    private func activityRow(_ entry: FeedEntry) -> some View {
        let isMissed = entry.activity.status == .planned &&
            !Calendar.current.isDate(entry.activity.date, equalTo: Date(), toGranularity: .month) &&
            entry.activity.date < Date()

        return HStack(alignment: .top, spacing: 12) {

            // Left: plant photo or type icon
            plantThumbnail(entry.plant)

            // Right: activity info
            VStack(alignment: .leading, spacing: 4) {
                // Plant name + activity type
                HStack {
                    Text(entry.plant.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(formatTime(entry.activity.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Activity type with icon + status badge
                HStack(spacing: 4) {
                    Image(systemName: entry.activity.type.icon)
                        .font(.caption)
                        .foregroundStyle(isMissed ? .secondary : entry.activity.type.color)

                    Text(entry.activity.type.localizedName)
                        .font(.caption)
                        .foregroundStyle(isMissed ? .secondary : entry.activity.type.color)

                    // Status badge
                    if isMissed {
                        Text(NSLocalizedString("Missed", comment: ""))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.red.opacity(0.15))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    } else if entry.activity.status == .planned {
                        Text(NSLocalizedString("Planned", comment: ""))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }

                    // Show who did it
                    if let name = entry.activity.memberName {
                        Text("· \(name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let variety = entry.plant.variety {
                        Text("· \(variety)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Optional note
                if let note = entry.activity.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }

                // Optional photo
                if let photoID = entry.activity.photoID {
                    ActivityPhotoThumbnail(photoID: photoID)
                        .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Plant Thumbnail
    // Small photo or type icon for the plant

    private func plantThumbnail(_ plant: Plant) -> some View {
        Group {
            if let photoID = plant.photoID,
               let image = PhotoManager.shared.load(id: photoID) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: plant.type.icon)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(plant.type.color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Data: Combine all activities from all plants

    // A FeedEntry pairs an activity with the plant it belongs to
    private var allActivities: [FeedEntry] {
        store.plants.flatMap { plant in
            plant.activities.map { activity in
                FeedEntry(plant: plant, activity: activity)
            }
        }
        .sorted { $0.activity.date > $1.activity.date }
    }

    // Apply the activity type filter
    private var filteredActivities: [FeedEntry] {
        if let filter = selectedFilter {
            return allActivities.filter { $0.activity.type == filter }
        }
        return allActivities
    }

    // Group filtered activities by date label
    private var groupedByDate: [String: [FeedEntry]] {
        Dictionary(grouping: filteredActivities) { entry in
            dateLabel(for: entry.activity.date)
        }
    }

    // MARK: - Helpers

    private func dateLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return NSLocalizedString("Today", comment: "")
        } else if calendar.isDateInYesterday(date) {
            return NSLocalizedString("Yesterday", comment: "")
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return NSLocalizedString("This Week", comment: "")
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .month) {
            return NSLocalizedString("This Month", comment: "")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Feed Entry
// Pairs an activity with its parent plant so we can show both in the feed.

struct FeedEntry: Identifiable {
    let plant: Plant
    let activity: CareActivity

    // Use the activity's ID as the unique identifier
    var id: UUID { activity.id }
}

// MARK: - Global Add Activity View
// A two-step flow: pick a plant → then log/plan an activity for it.
// Used from the Activity Feed tab's "+" button so you can add activities
// without first navigating to a specific plant.

struct GlobalAddActivityView: View {

    @Environment(PlantStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    // Step 1: which plant?
    @State private var selectedPlant: Plant?

    var body: some View {
        NavigationStack {
            if let plant = selectedPlant {
                // Step 2: log/plan the activity
                AddActivityView { activity in
                    // Find the plant in the store and add the activity
                    if let index = store.plants.firstIndex(where: { $0.id == plant.id }) {
                        store.plants[index].activities.append(activity)

                        // If it's a "done" watering, also update lastWatered
                        if activity.type == .watered && activity.status == .done {
                            store.plants[index].lastWatered = activity.date
                        }

                        store.save()
                    }
                    dismiss()
                }
            } else {
                // Step 1: pick a plant
                List {
                    if store.plants.isEmpty {
                        ContentUnavailableView(
                            NSLocalizedString("No Plants Yet", comment: ""),
                            systemImage: "leaf.fill",
                            description: Text(NSLocalizedString("Add a plant first, then you can log activities.", comment: ""))
                        )
                    } else {
                        ForEach(store.plants) { plant in
                            Button {
                                selectedPlant = plant
                            } label: {
                                HStack(spacing: 12) {
                                    // Plant photo or icon
                                    if let photoID = plant.photoID,
                                       let image = PhotoManager.shared.load(id: photoID) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Image(systemName: plant.type.icon)
                                            .font(.body)
                                            .foregroundStyle(.white)
                                            .frame(width: 40, height: 40)
                                            .background(plant.type.color.gradient)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(plant.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(plant.type.localizedName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .navigationTitle(NSLocalizedString("Choose Plant", comment: ""))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(NSLocalizedString("Cancel", comment: "")) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ActivityFeedView()
        .environment(PlantStore())
}
