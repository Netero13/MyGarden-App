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
    @State private var date: Date = Date()
    @State private var note: String = ""

    // Photo state
    @State private var selectedPhoto: UIImage?
    @State private var savedPhotoID: String?

    var body: some View {
        NavigationStack {
            Form {

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
                    Text("What did you do?")
                }

                // -- Date Picker --
                Section {
                    DatePicker(
                        "Date",
                        selection: $date,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                } header: {
                    Text("When?")
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
                                Label("Remove", systemImage: "xmark.circle.fill")
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
                    Text("Photo (optional)")
                } footer: {
                    Text("Take a photo of what you did — great for tracking progress!")
                }

                // -- Notes --
                Section {
                    TextField("Optional details...", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("e.g. \"applied organic fertilizer\" or \"picked 2kg of cherries\"")
                }
            }
            .navigationTitle("Log Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Clean up photo if user cancels
                        if let id = savedPhotoID {
                            PhotoManager.shared.delete(id: id)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let activity = CareActivity(
                            type: selectedType,
                            date: date,
                            note: note.isEmpty ? nil : note,
                            photoID: savedPhotoID
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

                Text(type.rawValue)
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
