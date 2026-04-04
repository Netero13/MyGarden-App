import SwiftUI

// MARK: - Encyclopedia View
// The Tree Encyclopedia — a browsable knowledge base of all trees and bushes.
// Users come here to discover species, learn about care, and add plants to their garden.
//
// Features:
// - Filter by type (fruit tree / forest tree / bush)
// - Search by name (English or Ukrainian)
// - Quick-glance stat cards (height, hardiness, sun, harvest)
// - Tap any species → full detail page with TreeIntelligence
// - "Add to my garden" button on each species
//
// This makes Arborist useful for PLANNING, not just tracking.

struct EncyclopediaView: View {

    @Environment(PlantStore.self) private var store

    // Filter: which type to show (nil = show all)
    @State private var selectedFilter: PlantType?

    // Search
    @State private var searchText: String = ""

    // Sheet: add plant from encyclopedia
    @State private var speciesForAdding: PlantSpecies?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // -- Filter Chips --
                filterBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                // -- Species List --
                if filteredSpecies.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredSpecies) { species in
                                NavigationLink {
                                    SpeciesDetailView(species: species) {
                                        speciesForAdding = species
                                    }
                                } label: {
                                    speciesCard(species)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Encyclopedia", comment: ""))
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: NSLocalizedString("Search trees & bushes...", comment: ""))
            .sheet(item: $speciesForAdding) { species in
                AddPlantFromEncyclopedia(species: species) { plant in
                    store.add(plant)
                }
            }
        }
    }

    // MARK: - Filter Bar
    // Horizontal row of capsule chips to filter by type.

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                filterChip(label: NSLocalizedString("All", comment: ""), icon: "tree.fill", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }

                // One chip per type
                ForEach(PlantType.allCases, id: \.self) { type in
                    filterChip(
                        label: type.localizedName,
                        icon: type.icon,
                        color: type.color,
                        isSelected: selectedFilter == type
                    ) {
                        selectedFilter = type
                    }
                }
            }
        }
    }

    private func filterChip(label: String, icon: String, color: Color = .green, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.1))
            .foregroundStyle(isSelected ? .white : color)
            .clipShape(Capsule())
        }
    }

    // MARK: - Species Card
    // A compact card showing key info at a glance.

    private func speciesCard(_ species: PlantSpecies) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: name + type badge
            HStack {
                // Type icon
                Image(systemName: species.type.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(species.type.color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(species.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(species.ukrainianName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Quick action badges
                VStack(alignment: .trailing, spacing: 4) {
                    Text(species.type.localizedName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(species.type.color.opacity(0.12))
                        .foregroundStyle(species.type.color)
                        .clipShape(Capsule())

                    if alreadyInGarden(species) {
                        Text(NSLocalizedString("In garden ✓", comment: ""))
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }

            // Quick stats row
            HStack(spacing: 16) {
                if let firstVariety = species.varieties.first {
                    statBadge(
                        icon: "arrow.up.to.line",
                        value: firstVariety.matureHeight,
                        color: .brown
                    )
                    statBadge(
                        icon: "thermometer.snowflake",
                        value: "\(firstVariety.frostHardiness)°C",
                        color: .cyan
                    )
                }
                statBadge(
                    icon: "sun.max.fill",
                    value: shortSunLabel(species.speciesInfo.sun),
                    color: .orange
                )
                if let harvest = species.varieties.first?.harvest {
                    statBadge(
                        icon: "basket.fill",
                        value: shortHarvestLabel(harvest.months),
                        color: .red
                    )
                    statBadge(
                        icon: "hourglass",
                        value: "\(harvest.yearsToBearing)y to fruit",
                        color: .purple
                    )
                }
            }

            // Varieties preview
            HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(species.varieties.prefix(3).map(\.name).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if species.varieties.count > 3 {
                    Text("+\(species.varieties.count - 3)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statBadge(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Data

    private var filteredSpecies: [PlantSpecies] {
        var result = TreeEncyclopedia.all

        // Apply type filter
        if let filter = selectedFilter {
            result = TreeEncyclopedia.species(for: filter)
        }

        // Apply search
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.ukrainianName.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    private func alreadyInGarden(_ species: PlantSpecies) -> Bool {
        store.plants.contains { $0.name == species.name }
    }

    // MARK: - Helpers

    private func shortSunLabel(_ full: String) -> String {
        if full.contains("Full sun to") { return "Sun/Shade" }
        if full.contains("Full sun") { return "Full sun" }
        if full.contains("Partial") { return "Partial" }
        return full
    }

    private func shortHarvestLabel(_ months: [Int]) -> String {
        let formatter = DateFormatter()
        let names = months.map { formatter.shortMonthSymbols[$0 - 1] }
        return names.joined(separator: "-")
    }
}

// MARK: - Species Detail View
// Full detail page for a single species — shows ALL intelligence data
// plus an "Add to my garden" button.

struct SpeciesDetailView: View {

    let species: PlantSpecies
    var onAddToGarden: () -> Void

    @Environment(PlantStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // -- Header --
                speciesHeader

                // -- Description / Key Facts --
                keyFactsCard

                // -- Varieties --
                varietiesCard

                // -- Full Care Intelligence --
                TreeIntelligenceView(
                    species: species,
                    plantAge: 0  // browsing mode — shows young tree info
                )

                // -- Add to Garden Button --
                if !alreadyInGarden {
                    addButton
                } else {
                    alreadyAddedBadge
                }
            }
            .padding()
        }
        .navigationTitle(species.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var speciesHeader: some View {
        VStack(spacing: 12) {
            // Big type icon
            Image(systemName: species.type.icon)
                .font(.system(size: 50))
                .foregroundStyle(.white)
                .frame(width: 90, height: 90)
                .background(species.type.color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Text(species.name)
                .font(.title)
                .fontWeight(.bold)

            Text(species.ukrainianName)
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text(species.type.localizedName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(species.type.color.opacity(0.15))
                    .foregroundStyle(species.type.color)
                    .clipShape(Capsule())

                if let years = species.varieties.first?.harvest?.yearsToBearing {
                    Text(String(format: NSLocalizedString("First fruit in ~%lld years", comment: ""), years))
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Key Facts Card

    private var keyFactsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundStyle(.blue)
                Text(NSLocalizedString("Key Facts", comment: ""))
                    .font(.headline)
                Spacer()
            }

            Divider()

            let resolved = species.resolvedIntelligence()

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                factCell(icon: "arrow.up.to.line", label: "Height", value: resolved.matureHeight, color: .brown)
                factCell(icon: "thermometer.snowflake", label: "Hardiness", value: "\(resolved.frostHardiness)°C", color: .cyan)
                factCell(icon: "sun.max.fill", label: "Sun", value: resolved.sunExposure, color: .orange)
                factCell(icon: "drop.halffull", label: "Soil pH", value: resolved.idealSoilPH, color: .teal)
                factCell(icon: "drop.fill", label: "Water (young)", value: "Every \(resolved.youngWateringDays)d", color: .blue)
                factCell(icon: "drop.fill", label: "Water (mature)", value: "Every \(resolved.establishedWateringDays)d", color: .blue.opacity(0.6))
            }

            if let months = resolved.harvestMonths {
                HStack {
                    Image(systemName: "basket.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(width: 20)
                    Text(String(format: NSLocalizedString("Harvest: %@", comment: ""), TreeIntelligence.monthNames(from: months)))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func factCell(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()
        }
        .padding(8)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Varieties Card

    private var varietiesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundStyle(.purple)
                Text(NSLocalizedString("Varieties", comment: ""))
                    .font(.headline)
                Spacer()
                Text("\(species.varieties.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Wrap varieties as flowing tags
            FlowLayout(spacing: 6) {
                ForEach(species.varieties) { variety in
                    Text(variety.name)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.purple.opacity(0.08))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            onAddToGarden()
        } label: {
            Label(NSLocalizedString("Add to My Garden", comment: ""), systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 4)
    }

    private var alreadyAddedBadge: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(NSLocalizedString("Already in your garden", comment: ""))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var alreadyInGarden: Bool {
        store.plants.contains { $0.name == species.name }
    }
}

// MARK: - Flow Layout
// A custom layout that wraps items to the next line when they don't fit.
// Used for variety tags so they flow naturally like text.
//
// Key concept: Layout protocol (iOS 16+)
// This tells SwiftUI exactly how to position each child view.

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                // Move to next line
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (positions, CGSize(width: maxWidth, height: totalHeight))
    }
}

// MARK: - Add Plant From Encyclopedia
// A simplified form for adding a plant when coming from the encyclopedia.
// The species is already chosen — just pick variety, planting year, photo.

struct AddPlantFromEncyclopedia: View {

    let species: PlantSpecies
    var onAdd: (Plant) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedVariety: String = ""
    @State private var customVariety: String = ""
    @State private var useCustomVariety: Bool = false
    @State private var birthYear: Int = Calendar.current.component(.year, from: Date())
    @State private var plantingYear: Int = Calendar.current.component(.year, from: Date())
    @State private var knowsPlantingYear: Bool = false
    @State private var selectedFrequency: WateringFrequency = .onceAWeek
    @State private var useCustomDays: Bool = false
    @State private var customDays: Int = 7

    var body: some View {
        NavigationStack {
            Form {
                // Species info (read-only)
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: species.type.icon)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(species.type.color.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(species.name)
                                .font(.headline)
                            Text(species.ukrainianName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(species.type.localizedName)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(species.type.color.opacity(0.12))
                            .foregroundStyle(species.type.color)
                            .clipShape(Capsule())
                    }
                }

                // Variety
                Section {
                    Toggle(NSLocalizedString("Custom variety", comment: ""), isOn: $useCustomVariety)

                    if useCustomVariety {
                        TextField(NSLocalizedString("Enter variety name", comment: ""), text: $customVariety)
                            .textInputAutocapitalization(.words)
                    } else {
                        Picker("Variety", selection: $selectedVariety) {
                            ForEach(species.varieties) { variety in
                                Text(variety.name).tag(variety.name)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                } header: {
                    Text(NSLocalizedString("Which variety?", comment: ""))
                }

                // Birth Year (required) & Planting Year (optional)
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
                }

                // Watering
                Section {
                    Toggle(NSLocalizedString("Custom schedule", comment: ""), isOn: $useCustomDays)

                    if useCustomDays {
                        Stepper("Every **\(customDays)** days", value: $customDays, in: 1...60)
                    } else {
                        Picker("Frequency", selection: $selectedFrequency) {
                            ForEach(WateringFrequency.allCases) { frequency in
                                Text(frequency.localizedName).tag(frequency)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }

                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text(String(format: NSLocalizedString("Recommended: every %lld days", comment: ""), species.defaultWateringDays))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(NSLocalizedString("Watering frequency", comment: ""))
                }
            }
            .navigationTitle(String(format: NSLocalizedString("Add %@", comment: ""), species.name))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Add", comment: "")) {
                        addPlant()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                // Pre-fill from encyclopedia
                if let first = species.varieties.first {
                    selectedVariety = first.name
                }
                let closest = WateringFrequency.closest(to: species.defaultWateringDays)
                selectedFrequency = closest
                customDays = species.defaultWateringDays
            }
        }
    }

    private func addPlant() {
        let variety: String? = useCustomVariety
            ? (customVariety.isEmpty ? nil : customVariety)
            : (selectedVariety.isEmpty ? nil : selectedVariety)

        let wateringDays = useCustomDays ? customDays : selectedFrequency.days

        let plant = Plant(
            name: species.name,
            type: species.type,
            variety: variety,
            birthYear: birthYear,
            plantingYear: knowsPlantingYear ? plantingYear : nil,
            wateringFrequencyDays: wateringDays,
            lastWatered: nil,
            dateAdded: Date()
        )

        onAdd(plant)
        dismiss()
    }
}

#Preview {
    EncyclopediaView()
        .environment(PlantStore())
}
