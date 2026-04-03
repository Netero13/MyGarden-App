import SwiftUI

// MARK: - Activity Feed View
// A unified timeline showing ALL activities across ALL plants.
// Think of it like a "news feed" for your garden — newest events first.
//
// Each entry shows:
// - Which plant it belongs to (with photo or icon)
// - What was done (watered, pruned, etc.)
// - When it was done
// - Optional note and photo
//
// You can also filter by activity type (show only watering, only pruning, etc.)

struct ActivityFeedView: View {

    // Access the shared plant store
    @Environment(PlantStore.self) private var store

    // Filter: which activity types to show (nil = show all)
    @State private var selectedFilter: CareType?

    var body: some View {
        NavigationStack {
            Group {
                if allActivities.isEmpty {
                    // No activities at all — empty state
                    ContentUnavailableView(
                        "No Activities Yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Start logging activities on your plants and they'll appear here.")
                    )
                } else if filteredActivities.isEmpty {
                    // Activities exist but none match the filter
                    ContentUnavailableView(
                        "No \(selectedFilter?.rawValue ?? "") Activities",
                        systemImage: selectedFilter?.icon ?? "magnifyingglass",
                        description: Text("No activities match this filter. Try a different one.")
                    )
                } else {
                    // Main list
                    List {
                        // Group activities by date (Today, Yesterday, Earlier, etc.)
                        ForEach(groupedByDate.keys.sorted().reversed(), id: \.self) { dateKey in
                            Section {
                                ForEach(groupedByDate[dateKey] ?? []) { entry in
                                    activityRow(entry)
                                }
                            } header: {
                                Text(dateKey)
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Activity Feed")
            .toolbar {
                // Filter menu in the top right
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        // "All" option
                        Button {
                            selectedFilter = nil
                        } label: {
                            if selectedFilter == nil {
                                Label("All Activities", systemImage: "checkmark")
                            } else {
                                Text("All Activities")
                            }
                        }

                        Divider()

                        // One option per activity type
                        ForEach(CareType.allCases) { type in
                            Button {
                                selectedFilter = type
                            } label: {
                                if selectedFilter == type {
                                    Label(type.rawValue, systemImage: "checkmark")
                                } else {
                                    Label(type.rawValue, systemImage: type.icon)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: selectedFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
        }
    }

    // MARK: - Activity Row
    // A single entry in the feed showing plant info + activity details.

    private func activityRow(_ entry: FeedEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {

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

                // Activity type with icon
                HStack(spacing: 4) {
                    Image(systemName: entry.activity.type.icon)
                        .font(.caption)
                        .foregroundStyle(entry.activity.type.color)

                    Text(entry.activity.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(entry.activity.type.color)

                    // Show who did it
                    if let member = FamilyManager.shared.member(for: entry.activity.memberID) {
                        Text("· \(member.emoji) \(member.name)")
                            .font(.caption)
                            .foregroundStyle(member.role.color)
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
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return "This Week"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .month) {
            return "This Month"
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

#Preview {
    ActivityFeedView()
        .environment(PlantStore())
}
