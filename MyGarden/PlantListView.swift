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

    // Controls the location permission prompt
    @State private var showingLocationPrompt: Bool = false

    // Navigation to filtered activity feed — set by tapping a dashboard stat card
    @State private var activityFilterDestination: CareType?
    @State private var showingFilteredFeed: Bool = false

    // Controls the "Plan / Log Activity" sheet (from toolbar)
    @State private var showingAddActivity: Bool = false

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

                // -- Arborist Insights (Arborist Engine) --
                if dashboardExpanded && arboristEngineEnabled {
                    arboristInsightsSection
                }

                // -- Smart Care (CareAction Engine) --
                if dashboardExpanded && careActionEngineEnabled {
                    smartCareSection
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
                            "\(type.localizedName) (\(groupedPlants[type]?.count ?? 0))",
                            systemImage: type.icon
                        )
                        .foregroundStyle(type.color)
                        .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .navigationTitle("Arborist")
            .searchable(text: $searchText, prompt: NSLocalizedString("Search plants...", comment: ""))
            .toolbar {
                // Left: app logo (matches the app icon)
                ToolbarItem(placement: .topBarLeading) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }

                // Right: "+" button — shows a menu to choose Plant or Activity
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddPlant = true
                        } label: {
                            Label(NSLocalizedString("New Plant", comment: ""), systemImage: "tree.fill")
                        }

                        Button {
                            showingAddActivity = true
                        } label: {
                            Label(NSLocalizedString("Plan / Log Activity", comment: ""), systemImage: "list.clipboard")
                        }
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
            .sheet(isPresented: $showingAddActivity) {
                GlobalAddActivityView()
            }
            // Navigate to filtered activity feed when tapping a dashboard stat card
            .sheet(isPresented: $showingFilteredFeed) {
                NavigationStack {
                    ActivityFeedView(selectedFilter: activityFilterDestination)
                        .environment(store)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(NSLocalizedString("Done", comment: "")) {
                                    showingFilteredFeed = false
                                }
                            }
                        }
                }
            }
            .overlay {
                if store.plants.isEmpty {
                    ContentUnavailableView(
                        NSLocalizedString("No Trees Yet", comment: ""),
                        systemImage: "tree.fill",
                        description: Text(NSLocalizedString("Tap + to add your first tree or bush!", comment: ""))
                    )
                }
            }
            // Fetch weather when view appears (async = non-blocking)
            .task {
                // If user chose GPS and we have permission, get fresh location first
                if LocationManager.shared.useGPSForWeather && LocationManager.shared.isAuthorized {
                    LocationManager.shared.requestLocation()
                } else {
                    await WeatherManager.shared.fetchWeather()
                }
            }
            // On first launch, ask user if they want GPS weather
            .onAppear {
                if !LocationManager.shared.hasBeenAsked {
                    // Small delay so the screen loads first, then show the prompt
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showingLocationPrompt = true
                    }
                }
            }
            // Location permission prompt — friendly, not pushy
            .alert(NSLocalizedString("Use Your Location for Weather?", comment: ""), isPresented: $showingLocationPrompt) {
                Button(NSLocalizedString("Allow", comment: "")) {
                    LocationManager.shared.useGPSForWeather = true
                    LocationManager.shared.requestPermission()
                }
                Button(NSLocalizedString("Pick City Instead", comment: ""), role: .cancel) {
                    LocationManager.shared.hasBeenAsked = true
                    LocationManager.shared.useGPSForWeather = false
                }
            } message: {
                Text(NSLocalizedString("MyGarden can use your location to show accurate weather and gardening tips for your area. You can always change this in Settings.", comment: ""))
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
                    Text(NSLocalizedString("Weather unavailable", comment: ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(NSLocalizedString("Retry", comment: "")) {
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
    // Clean briefing header — tells you what needs doing + your garden composition.
    // Tap to expand/collapse the rest of the dashboard.

    private var dashboardSection: some View {
        Section {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    dashboardExpanded.toggle()
                }
            } label: {
                dashboardHeader
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Dashboard Header
    // Top line: how many pending tasks (watering + care) or "All caught up!"
    // Bottom line: garden composition — "4 fruit · 3 berry · 2 forest"
    // Plus done-today count for satisfaction.

    private var dashboardHeader: some View {
        HStack(spacing: 12) {
            // Icon: orange clipboard if tasks pending, green checkmark if all done
            ZStack {
                Circle()
                    .fill(pendingTaskCount > 0 ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: pendingTaskCount > 0 ? "list.clipboard.fill" : "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(pendingTaskCount > 0 ? .orange : .green)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Main title: task count or "all done"
                if pendingTaskCount > 0 {
                    Text(pendingTaskCount == 1
                         ? NSLocalizedString("1 task for your garden", comment: "")
                         : String(format: NSLocalizedString("%lld tasks for your garden", comment: ""), pendingTaskCount))
                        .font(.headline)
                } else if todaysDoneCount > 0 {
                    Text(NSLocalizedString("All caught up!", comment: ""))
                        .font(.headline)
                } else {
                    Text(NSLocalizedString("Your garden is happy!", comment: ""))
                        .font(.headline)
                }

                // Subtitle: done today (if any) + garden composition by type
                HStack(spacing: 0) {
                    if todaysDoneCount > 0 {
                        Text(String(format: NSLocalizedString("%lld done today", comment: ""), todaysDoneCount))
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(" · ")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Garden composition: "4 fruit · 3 berry · 2 forest"
                    gardenCompositionText
                }
            }

            Spacer()

            Image(systemName: dashboardExpanded ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // Builds "4 fruit · 3 berry · 2 forest" as colored text
    private var gardenCompositionText: some View {
        let counts = typeCounts.sorted(by: { $0.value > $1.value })

        return HStack(spacing: 0) {
            ForEach(Array(counts.enumerated()), id: \.element.key) { index, entry in
                if index > 0 {
                    Text(" · ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("\(entry.value) ")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(entry.key.color)
                +
                Text(entry.key.localizedName.lowercased())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // Total pending tasks: watering + care this month
    private var pendingTaskCount: Int {
        plantsNeedingWaterCount + (careActionEngineEnabled ? careSingleTasksThisMonth.count : 0)
    }

    // How many activities were completed today
    private var todaysDoneCount: Int {
        let calendar = Calendar.current
        return store.plants.reduce(0) { count, plant in
            count + plant.activities.filter {
                $0.status == .done &&
                calendar.isDateInToday($0.completionDate ?? $0.date)
            }.count
        }
    }

    // MARK: - Arborist Insights Section (Arborist Engine)
    // When Arborist Engine is ON, shows AI-driven insights for the garden.
    // Currently: weather-based alerts (skip watering, frost risk, etc.)
    // Future: patterns from activity log, personalized recommendations.

    @ViewBuilder
    private var arboristInsightsSection: some View {
        if let weather = WeatherManager.shared.currentWeather, !store.plants.isEmpty {
            let alerts = gardenWeatherAlerts(weather: weather)
            if !alerts.isEmpty {
                Section {
                    ForEach(alerts) { alert in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(alert.color.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: alert.icon)
                                    .font(.callout)
                                    .foregroundStyle(alert.color)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(alert.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(alert.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if alert.isUrgent {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Label(NSLocalizedString("Arborist Insights", comment: ""), systemImage: "brain.head.profile.fill")
                        .foregroundStyle(.purple)
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
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
            Label(NSLocalizedString("Water Today", comment: ""), systemImage: "drop.fill")
                .foregroundStyle(.red)
                .font(.subheadline.weight(.semibold))
        }
    }

    // MARK: - Smart Care Section (CareAction Engine)
    // When CareAction Engine is ON, reads TreeIntelligence for each plant
    // and shows tasks due THIS month: pruning, fertilizing, harvesting,
    // pest/disease treatment. Like "Water Today" but for seasonal care.

    @ViewBuilder
    private var smartCareSection: some View {
        let tasks = careSingleTasksThisMonth
        if !tasks.isEmpty {
            Section {
                ForEach(tasks) { task in
                    if let species = TreeEncyclopedia.find(name: task.plant.name) {
                        // Tappable row — opens the intelligence detail page
                        NavigationLink {
                            CareActionDetailView(
                                plant: task.plant,
                                action: task.action,
                                species: species
                            )
                        } label: {
                            HStack(spacing: 12) {
                                // Left: action icon in a colored circle
                                Image(systemName: task.action.icon)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(task.action.color.gradient)
                                    .clipShape(Circle())

                                // Middle: action label + plant name
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.action.localizedLabel)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(task.action.color)

                                    Text(task.plant.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                // Right: done button (stops navigation propagation)
                                Button {
                                    performCareAction(task.action, for: task.plant.id)
                                } label: {
                                    Image(systemName: "checkmark")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(7)
                                        .background(task.action.color)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            } header: {
                Label(NSLocalizedString("Smart Care", comment: ""), systemImage: "leaf.arrow.triangle.circlepath")
                    .foregroundStyle(.orange)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    // Helper: calls the right store method for each care action
    private func performCareAction(_ action: CareAction, for plantID: UUID) {
        switch action {
        case .prune:            store.prune(id: plantID)
        case .fertilize:        store.fertilize(id: plantID)
        case .harvest:          store.harvest(id: plantID)
        case .pestTreatment:    store.treatPests(id: plantID)
        case .diseaseTreatment: store.treatDiseases(id: plantID)
        }
    }

    // MARK: - CareAction Engine: Tasks This Month
    // Reads TreeIntelligence for each plant and builds the list of pending tasks.
    // One row per action per plant. If Cherry needs prune + fertilize + pest treatment,
    // that's 3 separate items in the list — not 1 row with 3 tags.
    // Grouped by action type so all pruning tasks are together, then fertilizing, etc.

    private var careSingleTasksThisMonth: [CareSingleTask] {
        var tasks: [CareSingleTask] = []

        for plant in store.plants {
            guard let species = TreeEncyclopedia.find(name: plant.name) else { continue }
            let intel = species.resolvedIntelligence(forVariety: plant.variety)

            // Only show actions that are due AND not already done this month
            if intel.shouldPruneThisMonth() && !plant.wasDoneThisMonth(.pruned) {
                tasks.append(CareSingleTask(plant: plant, action: .prune))
            }
            if intel.shouldFertilizeThisMonth() && !plant.wasDoneThisMonth(.fertilized) {
                tasks.append(CareSingleTask(plant: plant, action: .fertilize))
            }
            if intel.isHarvestTime() && !plant.wasDoneThisMonth(.harvested) {
                tasks.append(CareSingleTask(plant: plant, action: .harvest))
            }
            if intel.shouldTreatPestsThisMonth() && !plant.wasDoneThisMonth(.pestControl) {
                tasks.append(CareSingleTask(plant: plant, action: .pestTreatment))
            }
            if intel.shouldTreatDiseasesThisMonth() && !plant.wasDoneThisMonth(.diseaseControl) {
                tasks.append(CareSingleTask(plant: plant, action: .diseaseTreatment))
            }
        }

        // Sort by action type so all pruning is together, then fertilizing, etc.
        let actionOrder: [CareAction] = [.prune, .fertilize, .harvest, .pestTreatment, .diseaseTreatment]
        tasks.sort { a, b in
            let aIndex = actionOrder.firstIndex(of: a.action) ?? 0
            let bIndex = actionOrder.firstIndex(of: b.action) ?? 0
            return aIndex < bIndex
        }

        return tasks
    }

    private var careActionEngineEnabled: Bool {
        UserDefaults.standard.bool(forKey: "careActionEngineEnabled")
    }

    private var arboristEngineEnabled: Bool {
        UserDefaults.standard.bool(forKey: "arboristEngineEnabled")
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
            return NSLocalizedString("Never watered", comment: "")
        }
        let days = Calendar.current.dateComponents([.day], from: nextDate, to: Date()).day ?? 0
        if days <= 0 {
            return NSLocalizedString("Due today", comment: "")
        } else if days == 1 {
            return NSLocalizedString("Overdue by 1 day", comment: "")
        } else {
            return String(format: NSLocalizedString("Overdue by %lld days", comment: ""), days)
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

    private var typeCounts: [PlantType: Int] {
        Dictionary(grouping: store.plants, by: { $0.type })
            .mapValues { $0.count }
    }

    // MARK: - Garden Weather Alerts (Phase 2)
    // Aggregates weather tips across ALL plants into garden-wide summaries.
    // Instead of showing 10 individual tips, we group them:
    // "3 plants: skip watering" or "Frost tonight — 2 plants at risk"

    private func gardenWeatherAlerts(weather: WeatherData) -> [GardenAlert] {
        var alerts: [GardenAlert] = []

        // Count plants by watering adjustment
        var skipCount = 0
        var delayCount = 0
        var increaseCount = 0
        var frostRiskCount = 0
        var fungalRiskCount = 0

        for plant in store.plants {
            let adjustment = WeatherIntelligence.wateringAdjustment(for: plant, weather: weather)
            switch adjustment {
            case .skip: skipCount += 1
            case .delay: delayCount += 1
            case .increase: increaseCount += 1
            case .slightlyMore: increaseCount += 1
            default: break
            }

            // Check for frost risk
            let tips = WeatherIntelligence.tips(for: plant, weather: weather)
            for tip in tips {
                if tip.icon == "thermometer.snowflake" || tip.icon == "snowflake" { frostRiskCount += 1; break }
            }
            for tip in tips {
                if tip.icon == "humidity.fill" { fungalRiskCount += 1; break }
            }
        }

        // Build alerts (most urgent first)
        if frostRiskCount > 0 {
            alerts.append(GardenAlert(
                icon: "thermometer.snowflake",
                color: .cyan,
                title: String(format: NSLocalizedString("Frost risk — %lld plants", comment: ""), frostRiskCount),
                subtitle: String(format: NSLocalizedString("Tonight drops to %.0f\u{00B0}C. Check plant details for specifics.", comment: ""), weather.todayMinTemp),
                isUrgent: weather.todayMinTemp <= -5
            ))
        }

        if skipCount > 0 {
            alerts.append(GardenAlert(
                icon: "cloud.rain.fill",
                color: .blue,
                title: String(format: NSLocalizedString("%lld plants: skip watering", comment: ""), skipCount),
                subtitle: String(format: NSLocalizedString("%.0f mm rain today — nature is doing the work!", comment: ""), weather.todayRainMM),
                isUrgent: false
            ))
        } else if delayCount > 0 {
            alerts.append(GardenAlert(
                icon: "clock.arrow.circlepath",
                color: .cyan,
                title: String(format: NSLocalizedString("%lld plants: can delay watering", comment: ""), delayCount),
                subtitle: NSLocalizedString("Rain expected tomorrow — you can wait.", comment: ""),
                isUrgent: false
            ))
        }

        if increaseCount > 0 {
            alerts.append(GardenAlert(
                icon: "sun.max.fill",
                color: .orange,
                title: String(format: NSLocalizedString("%lld plants need extra water", comment: ""), increaseCount),
                subtitle: String(format: NSLocalizedString("%.0f\u{00B0}C today — water in the evening for best results.", comment: ""), weather.todayMaxTemp),
                isUrgent: false
            ))
        }

        if fungalRiskCount > 0 {
            alerts.append(GardenAlert(
                icon: "humidity.fill",
                color: .green,
                title: String(format: NSLocalizedString("Fungal risk — %lld plants", comment: ""), fungalRiskCount),
                subtitle: String(format: NSLocalizedString("Humidity %lld%% + warm — watch for disease.", comment: ""), weather.humidity),
                isUrgent: false
            ))
        }

        return alerts
    }

}

// MARK: - Garden Alert Model
// A simple struct for dashboard-level weather alerts.
// These are aggregated across all plants (not per-plant like WeatherTip).

struct GardenAlert: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let isUrgent: Bool
}

// MARK: - Care Single Task
// One row per action per plant — used by "Smart Care" section.
// Example: Cherry + Prune = one task, Cherry + Fertilize = another task.

struct CareSingleTask: Identifiable {
    let plant: Plant
    let action: CareAction
    // Combine plant ID + action for a unique ID
    var id: String { "\(plant.id.uuidString)-\(action.rawValue)" }
}

// MARK: - Care Action
// The five types of seasonal care a plant might need this month.
// Prune, fertilize, harvest are the "basic three".
// Pest treatment and disease treatment follow the same monthly pattern.

enum CareAction: String, Hashable {
    case prune
    case fertilize
    case harvest
    case pestTreatment
    case diseaseTreatment

    var icon: String {
        switch self {
        case .prune:            return "scissors"
        case .fertilize:        return "leaf.arrow.circlepath"
        case .harvest:          return "basket.fill"
        case .pestTreatment:    return "ant.fill"
        case .diseaseTreatment: return "allergens"
        }
    }

    var color: Color {
        switch self {
        case .prune:            return .orange
        case .fertilize:        return .green
        case .harvest:          return .red
        case .pestTreatment:    return .red
        case .diseaseTreatment: return .purple
        }
    }

    var localizedLabel: String {
        switch self {
        case .prune:            return NSLocalizedString("Prune", comment: "")
        case .fertilize:        return NSLocalizedString("Fertilize", comment: "")
        case .harvest:          return NSLocalizedString("Harvest", comment: "")
        case .pestTreatment:    return NSLocalizedString("Pest Treatment", comment: "")
        case .diseaseTreatment: return NSLocalizedString("Disease Treatment", comment: "")
        }
    }
}

#Preview {
    PlantListView()
        .environment(PlantStore())
}
