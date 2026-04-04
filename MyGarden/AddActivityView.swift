import SwiftUI
import PhotosUI

// MARK: - Add Activity View
// A form that lets you log an activity for a plant.
// Pick what you did → optionally add a photo → optionally add a note → save.
// The date defaults to "now" but you can change it.

struct AddActivityView: View {

    // Send the new activity back to the detail screen
    var onAdd: (CareActivity) -> Void

    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var selectedType: CareType = .watered
    @State private var selectedStatus: ActivityStatus = .done
    @State private var date: Date = Date()
    @State private var note: String = ""

    // Photo state
    @State private var selectedPhoto: UIImage?
    @State private var savedPhotoID: String?

    var body: some View {
        NavigationStack {
            Form {

                // -- Logged by --
                if let name = UserDefaults.standard.string(forKey: "userName"),
                   !name.isEmpty {
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                            Text(String(format: NSLocalizedString("Logging as %@", comment: ""), name))
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                }

                // -- Activity Type Picker --
                Section {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 90))
                    ], spacing: 12) {
                        ForEach(CareType.allCases) { type in
                            activityButton(type)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(NSLocalizedString("What did you do?", comment: ""))
                }

                // -- Done or Planned? --
                // "Done" = log something you already did (default)
                // "Planned" = schedule something for later
                Section {
                    Picker(NSLocalizedString("Status", comment: ""), selection: $selectedStatus) {
                        Text(NSLocalizedString("Done", comment: "")).tag(ActivityStatus.done)
                        Text(NSLocalizedString("Planned", comment: "")).tag(ActivityStatus.planned)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(NSLocalizedString("Done or Planned?", comment: ""))
                } footer: {
                    Text(selectedStatus == .planned
                         ? NSLocalizedString("Choose 'Planned' to schedule this for later.", comment: "")
                         : NSLocalizedString("Logging an activity you already completed.", comment: ""))
                }

                Section {
                    if selectedStatus == .planned {
                        // Planned = future dates
                        DatePicker(
                            NSLocalizedString("Date", comment: ""),
                            selection: $date,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    } else {
                        // Done = past dates only
                        DatePicker(
                            NSLocalizedString("Date", comment: ""),
                            selection: $date,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text(selectedStatus == .planned
                         ? NSLocalizedString("When to do it?", comment: "")
                         : NSLocalizedString("When?", comment: ""))
                }

                // -- Photo --
                Section {
                    if let selectedPhoto = selectedPhoto {
                        HStack {
                            Image(uiImage: selectedPhoto)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Spacer()

                            Button(role: .destructive) {
                                if let id = savedPhotoID {
                                    PhotoManager.shared.delete(id: id)
                                }
                                self.selectedPhoto = nil
                                self.savedPhotoID = nil
                            } label: {
                                Label(NSLocalizedString("Remove", comment: ""), systemImage: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                    }

                    // Camera + Library options
                    PhotoSourcePicker { image in
                        if let oldID = savedPhotoID {
                            PhotoManager.shared.delete(id: oldID)
                        }
                        selectedPhoto = image
                        savedPhotoID = PhotoManager.shared.save(image)
                    }
                } header: {
                    Text(NSLocalizedString("Photo (optional)", comment: ""))
                } footer: {
                    Text(NSLocalizedString("Take a photo of what you did — great for tracking progress!", comment: ""))
                }

                // -- Notes --
                Section {
                    TextField(NSLocalizedString("Optional details...", comment: ""), text: $note, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text(NSLocalizedString("Notes", comment: ""))
                } footer: {
                    Text(NSLocalizedString("e.g. \"applied organic fertilizer\" or \"picked 2kg of cherries\"", comment: ""))
                }
            }
            .navigationTitle(NSLocalizedString("Log Activity", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        // Clean up photo if user cancels
                        if let id = savedPhotoID {
                            PhotoManager.shared.delete(id: id)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Save", comment: "")) {
                        let activity = CareActivity(
                            type: selectedType,
                            date: date,
                            note: note.isEmpty ? nil : note,
                            photoID: savedPhotoID,
                            memberName: UserDefaults.standard.string(forKey: "userName"),
                            status: selectedStatus
                        )
                        onAdd(activity)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    // MARK: - Activity Button

    private func activityButton(_ type: CareType) -> some View {
        let isSelected = selectedType == type

        return Button {
            selectedType = type
        } label: {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : type.color)

                Text(type.localizedName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? type.color : type.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? type.color : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddActivityView { activity in
        print("Added: \(activity.type.rawValue)")
    }
}
