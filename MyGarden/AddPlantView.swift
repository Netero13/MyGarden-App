import SwiftUI
import PhotosUI

// MARK: - Add Plant View
// This is the form where users add a new plant to their garden.
// It works in 3 steps:
//   1. Pick a plant TYPE (herb, tree, bush, etc.)
//   2. Pick a SPECIES from our catalog (Cherry, Basil, Oak, etc.)
//   3. Pick a VARIETY and set WATERING FREQUENCY
//
// Key SwiftUI concepts:
// - @Environment(\.dismiss): lets this screen close itself
// - @State: tracks what the user has selected so far
// - Picker: a dropdown/selection control
// - Form: a special list designed for settings and input forms

struct AddPlantView: View {

    // This closure sends the new plant back to the list when the user taps "Add"
    // Think of it as: "hey parent screen, here's the new plant I created!"
    var onAdd: (Plant) -> Void

    // Lets this screen close itself (go back to the list)
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State
    // These @State variables track what the user picks in the form.
    // Each one updates the UI automatically when changed.

    @State private var selectedType: PlantType = .fruitTree
    @State private var selectedSpecies: PlantSpecies?
    @State private var selectedVariety: String = ""
    @State private var customVariety: String = ""
    @State private var useCustomVariety: Bool = false

    // Age
    @State private var plantingYear: Int = Calendar.current.component(.year, from: Date())
    @State private var knowsPlantingYear: Bool = true

    // Watering
    @State private var selectedFrequency: WateringFrequency = .onceAWeek
    @State private var useCustomDays: Bool = false
    @State private var customDays: Int = 7

    // Photo
    @State private var selectedPhoto: UIImage?
    @State private var savedPhotoID: String?

    var body: some View {
        NavigationStack {
            Form {

                // -- Step 1: Pick Type --
                typeSection

                // -- Step 2: Pick Species --
                speciesSection

                // -- Step 3: Pick Variety --
                if selectedSpecies != nil {
                    varietySection
                }

                // -- Step 3.5: Planting Year --
                if selectedSpecies != nil {
                    plantingYearSection
                }

                // -- Step 4: Photo --
                if selectedSpecies != nil {
                    photoSection
                }

                // -- Step 5: Watering Frequency --
                if selectedSpecies != nil {
                    wateringSection
                }
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button (top left)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Clean up photo if user cancels
                        if let id = savedPhotoID {
                            PhotoManager.shared.delete(id: id)
                        }
                        dismiss()
                    }
                }

                // Add button (top right) — only enabled when a species is selected
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addPlant()
                    }
                    .disabled(selectedSpecies == nil)
                    .fontWeight(.bold)
                }
            }
            // When the user changes plant type, reset species & variety
            .onChange(of: selectedType) {
                selectedSpecies = nil
                selectedVariety = ""
                customVariety = ""
                useCustomVariety = false
            }
            // When the user picks a species, auto-set the watering frequency
            .onChange(of: selectedSpecies?.id) {
                if let species = selectedSpecies {
                    let closest = WateringFrequency.closest(to: species.defaultWateringDays)
                    selectedFrequency = closest
                    customDays = species.defaultWateringDays
                    // Pre-select first variety
                    if let firstVariety = species.varieties.first {
                        selectedVariety = firstVariety
                    }
                }
            }
        }
    }

    // MARK: - Type Section
    // A picker that shows all plant types with their icons and colors.

    private var typeSection: some View {
        Section {
            Picker("Type", selection: $selectedType) {
                ForEach(PlantType.allCases, id: \.self) { type in
                    Label(type.localizedName, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("What type of plant?")
        } footer: {
            Text("Choose the category that best fits your plant.")
        }
    }

    // MARK: - Species Section
    // Shows all plants from the catalog that match the selected type.
    // Each option shows the name + Ukrainian name.

    private var speciesSection: some View {
        Section {
            let species = PlantCatalog.species(for: selectedType)

            if species.isEmpty {
                Text("No plants in this category yet")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Plant", selection: $selectedSpecies) {
                    Text("Select a plant...")
                        .tag(nil as PlantSpecies?)

                    ForEach(species) { sp in
                        Text("\(sp.name) — \(sp.ukrainianName)")
                            .tag(sp as PlantSpecies?)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        } header: {
            Text("Which plant?")
        }
    }

    // MARK: - Variety Section
    // Shows varieties from the catalog + option to type a custom one.

    private var varietySection: some View {
        Section {
            if let species = selectedSpecies {

                // Toggle: use catalog variety or type your own
                Toggle("Custom variety", isOn: $useCustomVariety)

                if useCustomVariety {
                    // Free text input for custom variety name
                    TextField("Enter variety name", text: $customVariety)
                        .textInputAutocapitalization(.words)
                } else {
                    // Pick from catalog varieties
                    Picker("Variety", selection: $selectedVariety) {
                        ForEach(species.varieties, id: \.self) { variety in
                            Text(variety).tag(variety)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
        } header: {
            Text("Which variety?")
        } footer: {
            Text("Turn on 'Custom variety' if yours isn't in the list.")
        }
    }

    // MARK: - Planting Year Section
    // Knowing when the tree was planted is crucial for age-based care.
    // Young trees need more water, different pruning, etc.

    private var plantingYearSection: some View {
        Section {
            Toggle("I know when it was planted", isOn: $knowsPlantingYear)

            if knowsPlantingYear {
                Stepper("Year: **\(plantingYear)**", value: $plantingYear, in: 1950...Calendar.current.component(.year, from: Date()))

                // Show calculated age
                let age = Calendar.current.component(.year, from: Date()) - plantingYear
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.orange)
                    Text(age == 0 ? NSLocalizedString("Newly planted this year", comment: "") : String(format: NSLocalizedString("About %lld year(s) old", comment: ""), age))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("When was it planted?")
        } footer: {
            Text("Arborist adjusts watering, pruning, and fertilizer recommendations based on tree age.", comment: "")
        }
    }

    // MARK: - Photo Section
    // Optional photo for the plant's "profile picture"
    // Offers both camera and library options.

    private var photoSection: some View {
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
                // Delete old photo if replacing
                if let oldID = savedPhotoID {
                    PhotoManager.shared.delete(id: oldID)
                }
                selectedPhoto = image
                savedPhotoID = PhotoManager.shared.save(image)
            }
        } header: {
            Text("Photo (optional)")
        } footer: {
            Text("Take a photo or pick one from your library. You can always change it later.")
        }
    }

    // MARK: - Watering Section
    // Shows the frequency picker with friendly labels.
    // The catalog's default is pre-selected, but user can adjust.

    private var wateringSection: some View {
        Section {
            // Toggle between preset frequencies and custom days
            Toggle("Custom schedule", isOn: $useCustomDays)

            if useCustomDays {
                // Custom: user picks exact number of days with a stepper
                // Stepper = a +/- control to increase or decrease a number
                Stepper("Every **\(customDays)** days", value: $customDays, in: 1...60)
            } else {
                // Preset picker with friendly labels
                Picker("Frequency", selection: $selectedFrequency) {
                    ForEach(WateringFrequency.allCases) { frequency in
                        Text(frequency.localizedName).tag(frequency)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            // Show what the catalog recommends
            if let species = selectedSpecies {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text(String(format: NSLocalizedString("Recommended: every %lld days", comment: ""), species.defaultWateringDays))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("How often to water?")
        } footer: {
            Text("Based on Ukrainian climate (spring-summer). Adjust for your soil and conditions.")
        }
    }

    // MARK: - Add Plant Action
    // Creates the Plant object and sends it back to the list.

    private func addPlant() {
        guard let species = selectedSpecies else { return }

        // Determine the final variety string
        let variety: String? = useCustomVariety
            ? (customVariety.isEmpty ? nil : customVariety)
            : (selectedVariety.isEmpty ? nil : selectedVariety)

        // Determine the final watering days
        let wateringDays = useCustomDays ? customDays : selectedFrequency.days

        // Create the plant
        let newPlant = Plant(
            name: species.name,
            type: species.type,
            variety: variety,
            photoID: savedPhotoID,
            plantingYear: knowsPlantingYear ? plantingYear : nil,
            wateringFrequencyDays: wateringDays,
            lastWatered: nil,       // hasn't been watered yet
            dateAdded: Date()       // added right now
        )

        // Send it back to the list and close this screen
        onAdd(newPlant)
        dismiss()
    }
}

// MARK: - Make PlantSpecies equatable so Picker works
// Picker needs to compare values to know which one is selected.
// Equatable tells Swift "two PlantSpecies are the same if their IDs match".

extension PlantSpecies: Equatable {
    static func == (lhs: PlantSpecies, rhs: PlantSpecies) -> Bool {
        lhs.id == rhs.id
    }
}

extension PlantSpecies: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview

#Preview {
    AddPlantView { plant in
        print("Added: \(plant.displayName)")
    }
}
