import SwiftUI

// MARK: - Activity Timeline View
// Shows a chronological list of all activities done to a plant.
// Looks like a timeline/journal with dates, icons, and notes.
// Newest entries appear at the top.
//
// NEW: Includes filter chips to show only specific activity types
// (e.g., tap "Pruned" to see only pruning entries).
// Rows are tappable — tap to open the full ActivityDetailView.

struct ActivityTimelineView: View {

    let activities: [CareActivity]
    let plant: Plant  // needed so tapping a row can show the plant in ActivityDetailView

    // Filter: tap a chip to show only that activity type
    @State private var selectedFilter: CareType?

    var body: some View {
        if activities.isEmpty {
            // No activities yet — show a friendly hint
            VStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(NSLocalizedString("No activity yet", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(NSLocalizedString("Tap \"Log Activity\" to start tracking", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else {
            VStack(spacing: 12) {
                // -- Filter chips --
                // Only shows types that actually exist in this plant's activities.
                // Tap to filter, tap again to clear.
                filterChips

                // -- Timeline entries --
                VStack(spacing: 0) {
                    ForEach(filteredActivities) { activity in
                        NavigationLink {
                            ActivityDetailView(activity: activity, plant: plant)
                        } label: {
                            timelineRow(activity)
                        }
                        .buttonStyle(.plain)

                        // Divider between entries (but not after the last one)
                        if activity.id != filteredActivities.last?.id {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Filter Chips
    // Horizontal scrollable row of type buttons.
    // Only shows types present in this plant's activities.

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

                // One chip per activity type that exists
                ForEach(availableTypes, id: \.self) { type in
                    Button {
                        if selectedFilter == type {
                            selectedFilter = nil  // tap again to clear
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
        }
    }

    // Which CareTypes are present in this plant's activities
    private var availableTypes: [CareType] {
        let typeSet = Set(activities.map(\.type))
        // Return in the same order as CareType.allCases
        return CareType.allCases.filter { typeSet.contains($0) }
    }

    // Sort + filter activities
    private var filteredActivities: [CareActivity] {
        let sorted = activities.sorted { $0.date > $1.date }
        if let filter = selectedFilter {
            return sorted.filter { $0.type == filter }
        }
        return sorted
    }

    // MARK: - Timeline Row
    // A single entry in the timeline: icon + type + date + optional note

    private func timelineRow(_ activity: CareActivity) -> some View {
        let isMissed = activity.status == .planned &&
            !Calendar.current.isDate(activity.date, equalTo: Date(), toGranularity: .month) &&
            activity.date < Date()

        return HStack(alignment: .top, spacing: 12) {

            // Left: colored icon circle
            // Done = filled, Planned = outlined with dashed border, Missed = greyed out
            if activity.status == .planned {
                Image(systemName: activity.type.icon)
                    .font(.caption)
                    .foregroundStyle(isMissed ? .secondary : activity.type.color)
                    .frame(width: 32, height: 32)
                    .background(isMissed ? Color.secondary.opacity(0.1) : activity.type.color.opacity(0.1))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isMissed ? Color.secondary : activity.type.color,
                                style: StrokeStyle(lineWidth: 2, dash: [4, 3])
                            )
                    )
            } else {
                Image(systemName: activity.type.icon)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(activity.type.color.gradient)
                    .clipShape(Circle())
            }

            // Right: activity details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(activity.type.localizedName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    // Status badge: "Planned" or "Missed"
                    if isMissed {
                        Text(NSLocalizedString("Missed", comment: ""))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    } else if activity.status == .planned {
                        Text(NSLocalizedString("Planned", comment: ""))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }

                    // Show who did it
                    if let name = activity.memberName {
                        Text("· \(name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(formatDate(activity.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Optional note
                if let note = activity.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                // Optional photo thumbnail
                if let photoID = activity.photoID {
                    ActivityPhotoThumbnail(photoID: photoID)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Date Formatting
    // Shows relative dates: "Today", "Yesterday", or "Mar 28"

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return NSLocalizedString("Today", comment: "")
        } else if calendar.isDateInYesterday(date) {
            return NSLocalizedString("Yesterday", comment: "")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Activity Photo Thumbnail
// Loads and displays a small photo from disk for a timeline entry.

struct ActivityPhotoThumbnail: View {
    let photoID: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .onAppear {
            image = PhotoManager.shared.load(id: photoID)
        }
    }
}

#Preview {
    NavigationStack {
        ActivityTimelineView(activities: [
            CareActivity(type: .watered, date: Date(), note: nil),
            CareActivity(type: .pruned, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, note: "Removed dead branches"),
            CareActivity(type: .fertilized, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, note: "Organic compost"),
            CareActivity(type: .planted, date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, note: nil),
        ], plant: Plant.samples[0])
        .padding()
    }
}
