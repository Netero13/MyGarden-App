import SwiftUI

// MARK: - Activity Detail View
// A full-page view showing all details of a single care activity.
// Opens when you tap an activity row in the timeline or feed.
//
// Think of it like opening a "diary entry" — you see the full story:
// what was done, when, by whom, with notes and photos displayed large.

struct ActivityDetailView: View {

    let activity: CareActivity
    let plant: Plant

    @Environment(PlantStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long     // "April 3, 2026"
        f.timeStyle = .short    // "14:30"
        return f
    }()

    // Is this a planned activity from a past month that was never done?
    private var isMissed: Bool {
        activity.status == .planned &&
        !Calendar.current.isDate(activity.date, equalTo: Date(), toGranularity: .month) &&
        activity.date < Date()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // -- Header: large icon + type name --
                headerSection

                // -- Plant info --
                plantInfoCard

                // -- Details card (date, who, note) --
                detailsCard

                // -- Photo (full-width if available) --
                if let photoID = activity.photoID {
                    photoSection(photoID: photoID)
                }

                // -- "Mark as Done" button for planned activities --
                if activity.status == .planned && !isMissed {
                    markAsDoneButton
                }
            }
            .padding()
        }
        .navigationTitle(activity.type.localizedName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header
    // Large colored icon + activity type label

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Big colored circle with activity icon
            // Planned = outlined/dashed, Done = filled, Missed = greyed
            if activity.status == .planned {
                Image(systemName: activity.type.icon)
                    .font(.largeTitle)
                    .foregroundStyle(isMissed ? .secondary : activity.type.color)
                    .frame(width: 80, height: 80)
                    .background(isMissed ? Color.secondary.opacity(0.1) : activity.type.color.opacity(0.1))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isMissed ? Color.secondary : activity.type.color,
                                style: StrokeStyle(lineWidth: 2.5, dash: [6, 4])
                            )
                    )
            } else {
                Image(systemName: activity.type.icon)
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(activity.type.color.gradient)
                    .clipShape(Circle())
            }

            // Activity type name
            Text(activity.type.localizedName)
                .font(.title2)
                .fontWeight(.bold)

            // Status badge
            if isMissed {
                Text(NSLocalizedString("Missed", comment: ""))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            } else if activity.status == .planned {
                Text(NSLocalizedString("Planned", comment: ""))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Plant Info Card
    // Shows which plant this activity belongs to

    private var plantInfoCard: some View {
        HStack(spacing: 12) {
            // Plant photo or type icon
            if let photoID = plant.photoID,
               let image = PhotoManager.shared.load(id: photoID) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: plant.type.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(plant.type.color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.displayName)
                    .font(.headline)
                Text(plant.type.localizedName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Details Card
    // Date, who did it, and optional note

    private var detailsCard: some View {
        VStack(spacing: 16) {
            // Status (Planned / Done / Missed)
            detailRow(
                icon: activity.status == .done ? "checkmark.circle.fill" : (isMissed ? "exclamationmark.circle.fill" : "clock.fill"),
                label: NSLocalizedString("Status", comment: ""),
                value: isMissed ? NSLocalizedString("Missed", comment: "") : activity.status.localizedName
            )

            Divider()

            // Date
            detailRow(
                icon: "calendar",
                label: NSLocalizedString("Date", comment: ""),
                value: dateFormatter.string(from: activity.date)
            )

            // Completion date (if a planned activity was completed later)
            if let completionDate = activity.completionDate {
                Divider()
                detailRow(
                    icon: "checkmark.circle",
                    label: NSLocalizedString("Completed", comment: ""),
                    value: dateFormatter.string(from: completionDate)
                )
            }

            Divider()

            // Who did it
            if let name = activity.memberName, !name.isEmpty {
                detailRow(
                    icon: "person.fill",
                    label: NSLocalizedString("Done by", comment: ""),
                    value: name
                )
                Divider()
            }

            // Note
            if let note = activity.note, !note.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Text(NSLocalizedString("Notes", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(note)
                        .font(.body)
                        .padding(.leading, 28)
                }
            } else {
                detailRow(
                    icon: "note.text",
                    label: NSLocalizedString("Notes", comment: ""),
                    value: NSLocalizedString("No notes", comment: "")
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Detail Row

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Photo Section
    // Shows the activity photo in a large format

    private func photoSection(photoID: String) -> some View {
        Group {
            if let image = PhotoManager.shared.load(id: photoID) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(NSLocalizedString("Photo", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    // MARK: - Mark as Done Button
    // Only shown for planned activities that haven't been missed (current/future month).
    // Calls the matching store method which transitions planned→done.

    private var markAsDoneButton: some View {
        Button {
            switch activity.type {
            case .pruned:         store.prune(id: plant.id)
            case .fertilized:     store.fertilize(id: plant.id)
            case .harvested:      store.harvest(id: plant.id)
            case .pestControl:    store.treatPests(id: plant.id)
            case .diseaseControl: store.treatDiseases(id: plant.id)
            case .watered:        store.water(id: plant.id)
            default: break
            }
            dismiss()
        } label: {
            Label(NSLocalizedString("Mark as Done", comment: ""), systemImage: "checkmark.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(activity.type.color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
