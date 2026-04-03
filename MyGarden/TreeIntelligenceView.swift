import SwiftUI

// MARK: - Tree Intelligence View
// The "brain" display of Arborist — shows smart, personalized care info
// for a specific tree/bush based on its species, age, and current season.
//
// This is the KEY differentiator of the app. While other apps just track
// watering, Arborist tells you WHEN to prune, fertilize, harvest, and
// warns you about pests and diseases.

struct TreeIntelligenceView: View {

    let species: PlantSpecies
    let plantAge: Int?  // nil = unknown age

    var body: some View {
        VStack(spacing: 16) {

            // -- Header --
            intelligenceHeader

            // -- Current Season Tip (most important!) --
            currentSeasonCard

            // -- Action Alerts (prune now? fertilize now? harvest?) --
            actionAlerts

            // -- Watering Intelligence --
            wateringCard

            // -- Pruning Guide --
            pruningCard

            // -- Fertilizer Guide --
            fertilizerCard

            // -- Harvest Info (fruit trees & bushes only) --
            if species.intelligence.harvestMonths != nil {
                harvestCard
            }

            // -- Environment Info --
            environmentCard

            // -- Pests & Diseases --
            problemsCard
        }
    }

    // MARK: - Intelligence Header

    private var intelligenceHeader: some View {
        HStack {
            Image(systemName: "brain.head.profile.fill")
                .foregroundStyle(.orange)
            Text(NSLocalizedString("Care Intelligence", comment: ""))
                .font(.headline)
            Spacer()
            if let age = plantAge {
                Text(age == 0 ? NSLocalizedString("Newly planted", comment: "") : String(format: NSLocalizedString("%lld y old", comment: ""), age))
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.15))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Current Season Tip

    private var currentSeasonCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: seasonIcon)
                    .foregroundStyle(seasonColor)
                Text(String(format: NSLocalizedString("%@ Advice", comment: ""), currentSeasonName))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(species.intelligence.currentSeasonTip())
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(seasonColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Alerts

    @ViewBuilder
    private var actionAlerts: some View {
        let alerts = currentAlerts
        if !alerts.isEmpty {
            VStack(spacing: 8) {
                ForEach(alerts, id: \.title) { alert in
                    HStack(spacing: 10) {
                        Image(systemName: alert.icon)
                            .font(.callout)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(alert.color.gradient)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(alert.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(NSLocalizedString("NOW", comment: ""))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(alert.color.opacity(0.15))
                            .foregroundStyle(alert.color)
                            .clipShape(Capsule())
                    }
                    .padding(10)
                    .background(alert.color.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Watering Intelligence

    private var wateringCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                Text(NSLocalizedString("Watering", comment: ""))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            let intel = species.intelligence
            let recommended = intel.wateringDays(forAge: plantAge)

            HStack {
                Text(NSLocalizedString("Recommended", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: NSLocalizedString("Every %lld days", comment: ""), recommended))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                ageRow(String(format: NSLocalizedString("Young (0-%lld y)", comment: ""), intel.yearsToMature), days: intel.youngWateringDays, isActive: (plantAge ?? 0) < intel.yearsToMature)
                ageRow(String(format: NSLocalizedString("Mature (%lld-7 y)", comment: ""), intel.yearsToMature), days: intel.matureWateringDays, isActive: {
                    guard let age = plantAge else { return false }
                    return age >= intel.yearsToMature && age < 7
                }())
                ageRow(NSLocalizedString("Established (7y+)", comment: ""), days: intel.establishedWateringDays, isActive: (plantAge ?? 0) >= 7)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func ageRow(_ label: String, days: Int, isActive: Bool) -> some View {
        HStack {
            if isActive {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            } else {
                Image(systemName: "circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(isActive ? .primary : .secondary)
            Spacer()
            Text(String(format: NSLocalizedString("every %lld days", comment: ""), days))
                .font(.caption)
                .foregroundStyle(isActive ? .blue : .secondary)
                .fontWeight(isActive ? .medium : .regular)
        }
    }

    // MARK: - Pruning Card

    private var pruningCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "scissors")
                    .foregroundStyle(.green)
                Text(NSLocalizedString("Pruning", comment: ""))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if species.intelligence.shouldPruneThisMonth() {
                    Text(NSLocalizedString("This month!", comment: ""))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
            }

            Divider()

            HStack {
                Text(NSLocalizedString("Best months", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(CareIntelligence.monthNames(from: species.intelligence.pruningMonths))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Text(species.intelligence.pruningTips)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Fertilizer Card

    private var fertilizerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "leaf.arrow.circlepath")
                    .foregroundStyle(.brown)
                Text(NSLocalizedString("Fertilizing", comment: ""))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if species.intelligence.shouldFertilizeThisMonth() {
                    Text(NSLocalizedString("This month!", comment: ""))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.brown.opacity(0.15))
                        .foregroundStyle(.brown)
                        .clipShape(Capsule())
                }
            }

            Divider()

            if species.intelligence.fertilizerMonths.isEmpty {
                Text(NSLocalizedString("This species rarely needs fertilizer!", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Text(NSLocalizedString("Best months", comment: ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CareIntelligence.monthNames(from: species.intelligence.fertilizerMonths))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            Text(species.intelligence.fertilizerType)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Harvest Card

    private var harvestCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "basket.fill")
                    .foregroundStyle(.orange)
                Text(NSLocalizedString("Harvest", comment: ""))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if species.intelligence.isHarvestTime() {
                    Text(NSLocalizedString("Harvest time!", comment: ""))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }

            Divider()

            if let months = species.intelligence.harvestMonths {
                HStack {
                    Text(NSLocalizedString("Harvest months", comment: ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CareIntelligence.monthNames(from: months))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
            }

            if let years = species.intelligence.yearsToBearing {
                HStack {
                    Text(NSLocalizedString("Years to first harvest", comment: ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()

                    if let age = plantAge {
                        if age >= years {
                            Text(NSLocalizedString("Should be bearing!", comment: ""))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        } else {
                            let remaining = years - age
                            Text(String(format: NSLocalizedString("%lld more year(s)", comment: ""), remaining))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text(String(format: NSLocalizedString("~%lld years", comment: ""), years))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Environment Card

    private var environmentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "globe.europe.africa.fill")
                    .foregroundStyle(.teal)
                Text(NSLocalizedString("Environment", comment: ""))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            envRow(icon: "sun.max.fill", label: NSLocalizedString("Sun", comment: ""), value: species.intelligence.sunExposure)
            envRow(icon: "thermometer.snowflake", label: NSLocalizedString("Frost hardiness", comment: ""), value: "\(species.intelligence.frostHardiness)°C")
            envRow(icon: "drop.halffull", label: NSLocalizedString("Ideal soil pH", comment: ""), value: species.intelligence.idealSoilPH)
            envRow(icon: "arrow.up.to.line", label: NSLocalizedString("Mature height", comment: ""), value: species.intelligence.matureHeight)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func envRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.teal)
                .frame(width: 20)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    // MARK: - Pests & Diseases Card

    private var problemsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(NSLocalizedString("Watch Out For", comment: ""))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            if !species.intelligence.commonPests.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("Pests", comment: ""))
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(species.intelligence.commonPests.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !species.intelligence.commonDiseases.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("Diseases", comment: ""))
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(species.intelligence.commonDiseases.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private struct AlertItem {
        let icon: String
        let color: Color
        let title: String
        let subtitle: String
    }

    private var currentAlerts: [AlertItem] {
        var alerts: [AlertItem] = []
        let intel = species.intelligence

        if intel.shouldPruneThisMonth() {
            alerts.append(AlertItem(
                icon: "scissors", color: .green,
                title: NSLocalizedString("Time to prune!", comment: ""),
                subtitle: String(format: NSLocalizedString("This month is ideal for pruning %@", comment: ""), species.name)
            ))
        }
        if intel.shouldFertilizeThisMonth() {
            alerts.append(AlertItem(
                icon: "leaf.arrow.circlepath", color: .brown,
                title: NSLocalizedString("Time to fertilize!", comment: ""),
                subtitle: String(describing: intel.fertilizerType.prefix(60)) + "..."
            ))
        }
        if intel.isHarvestTime() {
            alerts.append(AlertItem(
                icon: "basket.fill", color: .orange,
                title: NSLocalizedString("Harvest time!", comment: ""),
                subtitle: String(format: NSLocalizedString("%@ is ready to harvest", comment: ""), species.name)
            ))
        }
        return alerts
    }

    private var currentSeasonName: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:  return NSLocalizedString("Spring", comment: "")
        case 6...8:  return NSLocalizedString("Summer", comment: "")
        case 9...11: return NSLocalizedString("Autumn", comment: "")
        default:     return NSLocalizedString("Winter", comment: "")
        }
    }

    private var seasonIcon: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:  return "leaf.fill"
        case 6...8:  return "sun.max.fill"
        case 9...11: return "leaf.arrow.triangle.circlepath"
        default:     return "snowflake"
        }
    }

    private var seasonColor: Color {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:  return .green
        case 6...8:  return .orange
        case 9...11: return .brown
        default:     return .cyan
        }
    }
}

#Preview {
    ScrollView {
        TreeIntelligenceView(
            species: PlantCatalog.fruitTrees[0],  // Cherry
            plantAge: 3
        )
        .padding()
    }
}
