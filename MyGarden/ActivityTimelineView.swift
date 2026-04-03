import SwiftUI

// MARK: - Activity Timeline View
// Shows a chronological list of all activities done to a plant.
// Looks like a timeline/journal with dates, icons, and notes.
// Newest entries appear at the top.

struct ActivityTimelineView: View {

    let activities: [CareActivity]

    var body: some View {
        if activities.isEmpty {
            // No activities yet — show a friendly hint
            VStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No activity yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Tap \"Log Activity\" to start tracking")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else {
            // Show timeline entries, newest first
            VStack(spacing: 0) {
                ForEach(sortedActivities) { activity in
                    timelineRow(activity)

                    // Divider between entries (but not after the last one)
                    if activity.id != sortedActivities.last?.id {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
        }
    }

    // Sort activities: newest first
    private var sortedActivities: [CareActivity] {
        activities.sorted { $0.date > $1.date }
    }

    // MARK: - Timeline Row
    // A single entry in the timeline: icon + type + date + optional note

    private func timelineRow(_ activity: CareActivity) -> some View {
        HStack(alignment: .top, spacing: 12) {

            // Left: colored icon circle
            Image(systemName: activity.type.icon)
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(activity.type.color.gradient)
                .clipShape(Circle())

            // Right: activity details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(activity.type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)

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
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
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
    ActivityTimelineView(activities: [
        CareActivity(type: .watered, date: Date(), note: nil),
        CareActivity(type: .pruned, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, note: "Removed dead branches"),
        CareActivity(type: .fertilized, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, note: "Organic compost"),
        CareActivity(type: .planted, date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, note: nil),
    ])
    .padding()
}
