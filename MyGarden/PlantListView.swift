import SwiftUI

// MARK: - Plant List View
// The main screen — a scrollable list of all your plants with a dashboard on top.
// The dashboard shows quick stats + plants that need watering today.
//
// Key concept: @Environment
// Instead of @State (local data that disappears), we use @Environment
// to access the shared PlantStore. Changes here are saved automatically.

struct PlantListView: View {

    // Access the shared PlantStore from the environment
    @Environment(PlantStore.self) private var store

    // Search text — filters the list as you type
    @State private var searchText: String = ""

    // Controls whether the "Add Plant" form is shown
    @State private var showingAddPlant: Bool = false

    // Controls collapsing the dashboard (tap to expand/collapse)
    @State private var dashboardExpanded: Bool = true

    var body: some View {
        // @Bindable lets us create bindings ($store.plants) from @Observable objects
        @Bindable var store = store

        NavigationStack {
            List {
                // -- Weather Widget --
                weatherSection

                // -- Dashboard Section --
                if !store.plants.isEmpty {
                    dashboardSection
                }

                // -- "Water Today" Quick List --
                if !plantsNeedingWaterList.isEmpty && dashboardExpanded {
                    waterTodaySection
                }

                // -- Plant Sections by Type --
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
                // Left: active member switcher (quick switch between family members)
                ToolbarItem(placement: .topBarLeading) {
                    if FamilyManager.shared.members.count > 1 {
                        Menu {
                            ForEach(FamilyManager.shared.members) { member in
                                Button {
                                    FamilyManager.shared.setActive(member)
                                } label: {
                                    HStack {
                                        Text("\(member.emoji) \(member.name)")
                                        if member.id == FamilyManager.shared.activeMemberID {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            if let member = FamilyManager.shared.activeMember {
                                Text(member.emoji)
                                    .font(.title2)
                            }
                        }
                    } else if let member = FamilyManager.shared.activeMember {
                        Text(member.emoji)
                            .font(.title2)
                    }
                }

                // Right: add plant
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
            // Fetch weather when view appears (async = non-blocking)
            .task {
                await WeatherManager.shared.fetchWeather()
            }
        }
    }

    // MARK: - Weather Section
    // Shows live weather with animated background at the very top.
    // Fetches from Open-Meteo API (free, no key needed).
    // Includes a gardening tip based on the current weather.

    private var weatherSection: some View {
        Section {
            if let weather = WeatherManager.shared.currentWeather {
                WeatherHeaderView(weather: weather)
                    .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            } else if WeatherManager.shared.isLoading {
                WeatherLoadingView()
            } else if WeatherManager.shared.errorMessage != nil {
                // Weather failed to load — show a subtle fallback, not an error
                HStack(spacing: 8) {
                    Image(systemName: "cloud.sun.fill")
                        .foregroundStyle(.secondary)
                    Text("Weather unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Retry") {
                        Task {
                            await WeatherManager.shared.fetchWeather()
                        }
                    }
                    .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Dashboard Section
    // A collapsible card at the top showing garden stats at a glance.
    // Tap the header to expand/collapse — saves space when scrolling.
    //
    // Key concept: LazyVGrid
    // Arranges items in a grid (2 columns here). "Lazy" means it only
    // creates the items that are visible on screen — efficient for big lists.

    private var dashboardSection: some View {
        Section {
            // Tap to expand/collapse
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    dashboardExpanded.toggle()
                }
            } label: {
                dashboardHeader
            }
            .buttonStyle(.plain)

            if dashboardExpanded {
                // Stats grid: 2 columns of stat cards
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    statCard(
                        icon: "leaf.fill",
                        label: "Total Plants",
                        value: "\(store.plants.count)",
                        color: .green
                    )

                    statCard(
                        icon: "drop.fill",
                        label: "Need Water",
                        value: "\(plantsNeedingWaterCount)",
                        color: plantsNeedingWaterCount > 0 ? .red : .blue
                    )

                    statCard(
                        icon: "checkmark.circle.fill",
                        label: "All Good",
                        value: "\(store.plants.count - plantsNeedingWaterCount)",
                        color: .green
                    )

                    statCard(
                        icon: "clock.arrow.circlepath",
                        label: "Activities",
                        value: "\(totalActivities)",
                        color: .orange
                    )
                }
                .padding(.vertical, 4)

                // Type breakdown — scrollable row of type chips
                typeBreakdownRow

                // Recent activity
                if let lastActivity = mostRecentActivity {
                    recentActivityRow(lastActivity)
                }
            }
        }
    }

    // MARK: - Dashboard Header
    // Shows the main watering status + chevron to expand/collapse.

    private var dashboardHeader: some View {
        HStack(spacing: 12) {
            // Watering status icon
            ZStack {
                Circle()
                    .fill(plantsNeedingWaterCount > 0 ? .red.opacity(0.15) : .green.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: plantsNeedingWaterCount > 0 ? "drop.triangle.fill" : "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(plantsNeedingWaterCount > 0 ? .red : .green)
            }

            VStack(alignment: .leading, spacing: 2) {
                if plantsNeedingWaterCount > 0 {
                    Text("\(plantsNeedingWaterCount) plant\(plantsNeedingWaterCount == 1 ? " needs" : "s need") watering")
                        .font(.headline)
                } else {
                    Text("All plants are happy!")
                        .font(.headline)
                }

                Text("\(store.plants.count) plants in your garden")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Expand/collapse chevron
            Image(systemName: dashboardExpanded ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Stat Card
    // A small colored card showing one stat (icon + number + label).
    // Used inside the LazyVGrid to show 4 stats in a 2×2 grid.

    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Type Breakdown Row
    // A horizontal scrollable row of "chips" — one per plant type.
    // Each chip shows the type icon, name, and count.
    // Much cleaner than the bar + tiny legend approach.

    private var typeBreakdownRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(typeCounts.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.caption2)
                            .foregroundStyle(type.color)

                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.bold)

                        Text(type.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(type.color.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Water Today Section
    // A dedicated section showing ONLY the plants that need watering right now.
    // Each row has a quick "Water" button so you don't have to open the detail page.

    private var waterTodaySection: some View {
        Section {
            ForEach(plantsNeedingWaterList) { plant in
                HStack(spacing: 12) {
                    // Plant icon or photo
                    if let photoID = plant.photoID,
                       let image = PhotoManager.shared.load(id: photoID) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: plant.type.icon)
                            .font(.callout)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(plant.type.color.gradient)
                            .clipShape(Circle())
                    }

                    // Name + how overdue
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plant.name)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(overdueText(for: plant))
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Spacer()

                    // Quick water button
                    Button {
                        store.water(id: plant.id)
                    } label: {
                        Image(systemName: "drop.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.blue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Label("Water Today", systemImage: "drop.fill")
                .foregroundStyle(.red)
                .font(.subheadline.weight(.semibold))
        }
    }

    // MARK: - Recent Activity Row
    // Shows the most recent activity across all plants — a quick glance
    // at what you last did in your garden.

    private func recentActivityRow(_ entry: (plant: Plant, activity: CareActivity)) -> some View {
        HStack(spacing: 10) {
            Image(systemName: entry.activity.type.icon)
                .font(.callout)
                .foregroundStyle(entry.activity.type.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text("Last: \(entry.activity.type.rawValue) — \(entry.plant.name)")
                    .font(.caption)
                    .fontWeight(.medium)
                Text(entry.activity.date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func deleteFilteredPlants(type: PlantType, at offsets: IndexSet) {
        let plantsInSection = groupedPlants[type] ?? []
        for offset in offsets {
            let plantToDelete = plantsInSection[offset]
            store.delete(id: plantToDelete.id)
        }
    }

    private func overdueText(for plant: Plant) -> String {
        guard let nextDate = plant.nextWateringDate else {
            return "Never watered"
        }
        let days = Calendar.current.dateComponents([.day], from: nextDate, to: Date()).day ?? 0
        if days <= 0 {
            return "Due today"
        } else if days == 1 {
            return "Overdue by 1 day"
        } else {
            return "Overdue by \(days) days"
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

    private var plantsNeedingWaterCount: Int {
        store.plants.filter { $0.needsWatering }.count
    }

    private var plantsNeedingWaterList: [Plant] {
        store.plants.filter { $0.needsWatering }
    }

    private var totalActivities: Int {
        store.plants.reduce(0) { $0 + $1.activities.count }
    }

    private var typeCounts: [PlantType: Int] {
        Dictionary(grouping: store.plants, by: { $0.type })
            .mapValues { $0.count }
    }

    // Find the most recent activity across ALL plants
    private var mostRecentActivity: (plant: Plant, activity: CareActivity)? {
        var latest: (plant: Plant, activity: CareActivity)?
        for plant in store.plants {
            for activity in plant.activities {
                if latest == nil || activity.date > latest!.activity.date {
                    latest = (plant, activity)
                }
            }
        }
        return latest
    }
}

#Preview {
    PlantListView()
        .environment(PlantStore())
}
