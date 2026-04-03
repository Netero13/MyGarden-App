import SwiftUI

// MARK: - Plant List View
// The main screen — a scrollable list of all your plants.
// Now powered by PlantStore — plants are saved to disk automatically!
//
// Key change: instead of @State (local data that disappears),
// we now use @Environment to access the shared PlantStore.
// This means: add a plant here → it's saved. Delete → saved. Water → saved.

struct PlantListView: View {

    // Access the shared PlantStore from the environment.
    // This was set up in MyGardenApp.swift with .environment(store)
    @Environment(PlantStore.self) private var store

    // Search text — filters the list as you type
    @State private var searchText: String = ""

    // Controls whether the "Add Plant" form is shown
    @State private var showingAddPlant: Bool = false

    var body: some View {
        // @Bindable lets us create bindings ($store.plants) from @Observable objects
        @Bindable var store = store

        NavigationStack {
            List {
                // -- Watering Summary --
                wateringSummarySection

                // -- Plant Sections --
                ForEach(groupedPlants.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { type in
                    Section {
                        ForEach(groupedPlants[type] ?? []) { plant in
                            if let index = store.plants.firstIndex(where: { $0.id == plant.id }) {
                                NavigationLink {
                                    PlantDetailView(plant: $store.plants[index])
                                } label: {
                                    PlantRowView(plant: plant)
                                }
                            }
                        }
                        // SWIPE TO DELETE
                        // .onDelete tells SwiftUI: "when the user swipes left on a row,
                        // show a red Delete button". The closure receives the positions
                        // to delete. We need to convert filtered positions to real positions.
                        .onDelete { offsets in
                            deleteFilteredPlants(type: type, at: offsets)
                        }
                    } header: {
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
            .toolbar {
                // + button to add a new plant
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPlant = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlant) {
                AddPlantView { newPlant in
                    store.add(newPlant)
                }
            }
            .overlay {
                if store.plants.isEmpty {
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

    private var wateringSummarySection: some View {
        Section {
            HStack {
                Image(systemName: "drop.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading) {
                    Text("\(plantsNeedingWater) plants need watering")
                        .font(.headline)

                    Text("\(store.plants.count) plants total in your garden")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Delete Helper
    // When the list is filtered/grouped, the swipe position doesn't match
    // the real position in store.plants. So we find the actual plant IDs
    // from the filtered list and delete by ID.

    private func deleteFilteredPlants(type: PlantType, at offsets: IndexSet) {
        let plantsInSection = groupedPlants[type] ?? []
        for offset in offsets {
            let plantToDelete = plantsInSection[offset]
            store.delete(id: plantToDelete.id)
        }
    }

    // MARK: - Computed Properties

    private var groupedPlants: [PlantType: [Plant]] {
        Dictionary(grouping: filteredPlants, by: { $0.type })
    }

    private var filteredPlants: [Plant] {
        if searchText.isEmpty {
            return store.plants
        }
        return store.plants.filter { plant in
            plant.name.localizedCaseInsensitiveContains(searchText) ||
            (plant.variety?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var plantsNeedingWater: Int {
        store.plants.filter { $0.needsWatering }.count
    }
}

#Preview {
    PlantListView()
        .environment(PlantStore())
}
