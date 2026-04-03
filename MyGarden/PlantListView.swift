import SwiftUI

// MARK: - Plant List View
// This is the MAIN screen of the app — a scrollable list of all your plants.
// Plants are grouped by type (herbs, trees, bushes, etc.) with section headers.
//
// Key SwiftUI concepts used here:
// - List: a scrollable, tappable list (like a table in other frameworks)
// - Section: groups items under a header
// - ForEach: loops through items to create views for each one
// - @State: a variable that SwiftUI watches — when it changes, the screen updates

struct PlantListView: View {

    // @State means SwiftUI "watches" this variable.
    // When plants change (add/remove), the list automatically refreshes.
    // For now we use sample data — later we'll load real saved plants.
    @State private var plants: [Plant] = Plant.samples

    // Search text — filters the list as you type
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            List {
                // -- Watering Summary --
                // A quick glance at how many plants need attention
                wateringSummarySection

                // -- Plant Sections --
                // Loop through each plant type that has plants,
                // and create a section with a header for each type
                ForEach(groupedPlants.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { type in
                    Section {
                        ForEach(groupedPlants[type] ?? []) { plant in
                            PlantRowView(plant: plant)
                        }
                    } header: {
                        // Section header: icon + type name + count
                        Label(
                            "\(type.rawValue) (\(groupedPlants[type]?.count ?? 0))",
                            systemImage: type.icon
                        )
                        .foregroundStyle(type.color)
                        .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .navigationTitle("My Garden 🌱")
            .searchable(text: $searchText, prompt: "Search plants...")
            .overlay {
                // Show a friendly message if the list is empty
                if plants.isEmpty {
                    ContentUnavailableView(
                        "No Plants Yet",
                        systemImage: "leaf.fill",
                        description: Text("Tap + to add your first plant!")
                    )
                }
            }
        }
    }

    // MARK: - Watering Summary Section
    // Shows a card at the top: "X plants need watering"
    // This gives users instant awareness without scrolling through everything.

    private var wateringSummarySection: some View {
        Section {
            HStack {
                Image(systemName: "drop.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading) {
                    Text("\(plantsNeedingWater) plants need watering")
                        .font(.headline)

                    Text("\(plants.count) plants total in your garden")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Computed Properties
    // These calculate values on-the-fly from the current data.
    // They update automatically whenever 'plants' or 'searchText' changes.

    // Filters plants based on search text, then groups them by type.
    // Dictionary(grouping:by:) is a Swift function that sorts items into buckets.
    // Example: all herbs go into one bucket, all trees into another.
    private var groupedPlants: [PlantType: [Plant]] {
        let filtered = filteredPlants
        return Dictionary(grouping: filtered, by: { $0.type })
    }

    // Filters the plant list based on what the user typed in the search bar.
    // It checks both the plant name AND variety.
    private var filteredPlants: [Plant] {
        if searchText.isEmpty {
            return plants
        }
        return plants.filter { plant in
            plant.name.localizedCaseInsensitiveContains(searchText) ||
            (plant.variety?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // Counts how many plants need watering right now
    private var plantsNeedingWater: Int {
        plants.filter { $0.needsWatering }.count
    }
}

// MARK: - Preview
// Shows the full list screen with sample data in Xcode's preview canvas.

#Preview {
    PlantListView()
}
