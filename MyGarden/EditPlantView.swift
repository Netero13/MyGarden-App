import SwiftUI
import PhotosUI

// MARK: - Edit Plant View
// This form lets users CHANGE a plant's details after it's been created.
// It's similar to AddPlantView but works differently:
//
// Key difference: AddPlantView creates a NEW plant from scratch.
// EditPlantView takes an EXISTING plant and lets you modify it.
//
// How it works:
// 1. We receive the current plant data
// 2. We copy each value into @State variables (so changes are temporary)
// 3. The user edits whatever they want
// 4. When they tap "Save", we build an updated plant and send it back
// 5. If they tap "Cancel", nothing changes — the copy is thrown away
//
// This "edit a copy, then save" pattern is very common in iOS apps.
// It prevents the app from showing half-edited data while the user is still typing.

struct EditPlantView: View {

    // The original plant we're editing (read-only — we don't modify it directly)
    let plant: Plant

    // This closure sends the updated plant back to the detail screen
    // Think of it as: "hey parent, here's the edited version!"
    var onSave: (Plant) -> Void

    // Lets this screen close itself
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State
    // Each @State variable holds a COPY of one plant property.
    // The user edits these copies. The original plant stays untouched
    // until the user taps "Save".

    @State private var name: String = ""
    @State private var variety: String = ""
    @State private var selectedFrequency: WateringFrequency = .onceAWeek
    @State private var useCustomDays: Bool = false
    @State private var customDays: Int = 7
    @State private var birthYear: Int = Calendar.current.component(.year, from: Date())
    @State private var plantingYear: Int = Calendar.current.component(.year, from: Date())
    @State private var knowsPlantingYear: Bool = false
    @State private var currentPhoto: UIImage?
    @State private var newPhotoID: String?
    @State private var photoChanged: Bool = false

    var body: some View {
        NavigationStack {
            Form {

                // -- Section 1: Name & Variety --
                nameSection

                // -- Section 2: Birth Year (required) & Planting Year (optional) --
                Section {
                    // Birth year — REQUIRED
                    Stepper(
                        String(format: NSLocalizedString("Born: %lld", comment: ""), birthYear),
                        value: $birthYear,
                        in: 1900...Calendar.current.component(.year, from: Date())
                    )

                    let age = Calendar.current.component(.year, from: Date()) - birthYear
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.orange)
                        Text(age == 0
                             ? NSLocalizedString("Newly planted this year", comment: "")
                             : String(format: NSLocalizedString("About %lld year(s) old", comment: ""), age))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Planting year — optional
                    Toggle(NSLocalizedString("I know when it was planted", comment: ""), isOn: $knowsPlantingYear)

                    if knowsPlantingYear {
                        Stepper(
                            String(format: NSLocalizedString("Planted: %lld", comment: ""), plantingYear),
                            value: $plantingYear,
                            in: 1950...Calendar.current.component(.year, from: Date())
                        )
                    }
                } header: {
                    Text(NSLocalizedString("How old is the tree?", comment: ""))
                } footer: {
                    Text(NSLocalizedString("Birth year is used for age-based care. Arborist adjusts watering, pruning, and fertilizer recommendations based on tree age.", comment: ""))
                }

                // -- Section 3: Photo --
                photoSection

                // -- Section 3: Watering Frequency --
                wateringSection

                // -- Section 4: Plant Info (read-only) --
                infoSection
            }
            .navigationTitle(NSLocalizedString("Edit Plant", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button — discards all changes
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        // If user took a new photo but cancels, clean up the file
                        if let id = newPhotoID {
                            PhotoManager.shared.delete(id: id)
                        }
                        dismiss()
                    }
                }

                // Save button — applies all changes
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Save", comment: "")) {
                        savePlant()
                    }
                    .fontWeight(.bold)
                    // Disable save if name is empty
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            // When the view first appears, populate the form with current plant data
            .onAppear {
                loadPlantData()
            }
        }
    }

    // MARK: - Name & Variety Section
    // Text fields for the plant's name and optional variety.

    private var nameSection: some View {
        Section {
            // Plant name — required
            // TextField = a text box the user can type into
            HStack {
                Label(NSLocalizedString("Name", comment: ""), systemImage: "leaf.fill")
                    .foregroundStyle(.secondary)
                TextField(NSLocalizedString("Plant name", comment: ""), text: $name)
                    .multilineTextAlignment(.trailing)
            }

            // Variety — optional
            HStack {
                Label(NSLocalizedString("Variety", comment: ""), systemImage: "tag.fill")
                    .foregroundStyle(.secondary)
                TextField(NSLocalizedString("Variety (optional)", comment: ""), text: $variety)
                    .multilineTextAlignment(.trailing)
            }
        } header: {
            Text(NSLocalizedString("Name & Variety", comment: ""))
        } footer: {
            Text(NSLocalizedString("The name is what you see in the plant list. Variety is shown below it.", comment: ""))
        }
    }

    // MARK: - Photo Section
    // Shows current photo (if any) and lets the user change or remove it.

    private var photoSection: some View {
        Section {
            // Show current photo preview
            if let photo = currentPhoto {
                HStack {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Spacer()

                    // Remove photo button
                    Button(role: .destructive) {
                        // If we saved a new photo, delete it
                        if let id = newPhotoID {
                            PhotoManager.shared.delete(id: id)
                            newPhotoID = nil
                        }
                        currentPhoto = nil
                        photoChanged = true
                    } label: {
                        Label(NSLocalizedString("Remove", comment: ""), systemImage: "xmark.circle.fill")
                            .font(.caption)
                    }
                }
            }

            // Camera + Library picker to change the photo
            PhotoSourcePicker { image in
                // Delete the previously saved new photo (if user changes photo multiple times)
                if let oldNewID = newPhotoID {
                    PhotoManager.shared.delete(id: oldNewID)
                }
                currentPhoto = image
                newPhotoID = PhotoManager.shared.save(image)
                photoChanged = true
            }
        } header: {
            Text(NSLocalizedString("Photo", comment: ""))
        } footer: {
            if plant.photoID != nil && !photoChanged {
                Text(NSLocalizedString("Your plant already has a photo. You can change it or remove it.", comment: ""))
            } else if photoChanged {
                Text(NSLocalizedString("Photo will be updated when you save.", comment: ""))
            } else {
                Text(NSLocalizedString("Add a photo to recognize your plant easily.", comment: ""))
            }
        }
    }

    // MARK: - Watering Section
    // Same picker as AddPlantView — preset frequencies or custom days.

    private var wateringSection: some View {
        Section {
            // Toggle between friendly presets and exact number of days
            Toggle(NSLocalizedString("Custom schedule", comment: ""), isOn: $useCustomDays)

            if useCustomDays {
                // Stepper = +/- buttons to adjust a number
                Stepper("Every **\(customDays)** days", value: $customDays, in: 1...60)
            } else {
                // Dropdown with friendly labels like "Once a week", "Every other day"
                Picker("Frequency", selection: $selectedFrequency) {
                    ForEach(WateringFrequency.allCases) { frequency in
                        Text(frequency.localizedName).tag(frequency)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            // Show current frequency for reference
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                Text(String(format: NSLocalizedString("Currently: every %lld days", comment: ""), plant.wateringFrequencyDays))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(NSLocalizedString("Watering Frequency", comment: ""))
        } footer: {
            Text(NSLocalizedString("Adjust based on the season and your soil conditions.", comment: ""))
        }
    }

    // MARK: - Info Section (Read-Only)
    // Shows some info that can't be changed (type, date added).
    // This gives the user context while editing.

    private var infoSection: some View {
        Section {
            // Plant type — can't be changed (would need a different plant)
            HStack {
                Label(NSLocalizedString("Type", comment: ""), systemImage: plant.type.icon)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(plant.type.localizedName)
                    .foregroundStyle(plant.type.color)
                    .fontWeight(.medium)
            }

            // Date added — historical, can't change
            HStack {
                Label(NSLocalizedString("Added to Garden", comment: ""), systemImage: "calendar.badge.plus")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(plant.dateAdded, style: .date)
            }

            // Activity count — informational
            HStack {
                Label(NSLocalizedString("Activities", comment: ""), systemImage: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(plant.activities.count)")
            }
        } header: {
            Text(NSLocalizedString("Plant Info", comment: ""))
        } footer: {
            Text(NSLocalizedString("Type and date added can't be changed.", comment: ""))
        }
    }

    // MARK: - Load Plant Data
    // Called when the view appears. Copies the plant's current values
    // into our @State variables so the form is pre-filled.
    //
    // Why not set these in the @State declarations?
    // Because @State initializers run before the view's `plant` property
    // is available. So we use .onAppear to set them after everything is ready.

    private func loadPlantData() {
        name = plant.name
        variety = plant.variety ?? ""

        // Figure out which frequency preset matches (or use custom)
        let closest = WateringFrequency.closest(to: plant.wateringFrequencyDays)
        if closest.days == plant.wateringFrequencyDays {
            // Exact match — use the preset
            selectedFrequency = closest
            useCustomDays = false
        } else {
            // No exact match — use custom mode
            useCustomDays = true
        }
        customDays = plant.wateringFrequencyDays

        // Load birth year (always present)
        birthYear = plant.birthYear

        // Load planting year (optional)
        if let year = plant.plantingYear {
            plantingYear = year
            knowsPlantingYear = true
        } else {
            knowsPlantingYear = false
        }

        // Load the current photo from disk
        if let photoID = plant.photoID {
            currentPhoto = PhotoManager.shared.load(id: photoID)
        }
    }

    // MARK: - Save Plant
    // Builds an updated Plant from the form values and sends it back.
    // The parent screen (PlantDetailView) will call store.update() to persist it.

    private func savePlant() {
        // Build the updated plant — start with a copy to keep id, dateAdded, activities
        var updated = plant

        // Apply the edits
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.variety = variety.trimmingCharacters(in: .whitespaces).isEmpty ? nil : variety.trimmingCharacters(in: .whitespaces)
        updated.wateringFrequencyDays = useCustomDays ? customDays : selectedFrequency.days
        updated.birthYear = birthYear
        updated.plantingYear = knowsPlantingYear ? plantingYear : nil

        // Handle photo changes
        if photoChanged {
            // Delete the old photo file (if there was one)
            if let oldID = plant.photoID {
                PhotoManager.shared.delete(id: oldID)
            }
            // Set the new photo ID (could be nil if user removed the photo)
            updated.photoID = newPhotoID
        }

        // Send the updated plant back and close the form
        onSave(updated)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    EditPlantView(plant: Plant.samples[0]) { updated in
        print("Saved: \(updated.displayName)")
    }
}
