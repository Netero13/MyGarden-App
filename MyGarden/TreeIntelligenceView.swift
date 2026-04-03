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
            Text("Care Intelligence")
                .font(.headline)
            Spacer()
            if let age = plantAge {
                Text(age == 0 ? "Newly planted" : "\(age)y old")
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
                Text("\(currentSeasonName) Advice")
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
    // Shows urgent actions: "Prune this month!", "Time to fertilize!", "Harvest!"

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

                        Text("NOW")
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
                Text("Watering")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            // Age-based recommendation
            let intel = species.intelligence
            let recommended = intel.wateringDays(forAge: plantAge)

            HStack {
                Text("Recommended")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Every \(recommended) days")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }

            // Age breakdown
            VStack(alignment: .leading, spacing: 4) {
                ageRow("Young (0-\(intel.yearsToMature)y)", days: intel.youngWateringDays, isActive: (plantAge ?? 0) < intel.yearsToMature)
                ageRow("Mature (\(intel.yearsToMature)-7y)", days: intel.matureWateringDays, isActive: {
                    guard let age = plantAge else { return false }
                    return age >= intel.yearsToMature && age < 7
                }())
                ageRow("Established (7y+)", days: intel.establishedWateringDays, isActive: (plantAge ?? 0) >= 7)
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
            Text("every \(days) days")
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
                Text("Pruning")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if species.intelligence.shouldPruneThisMonth() {
                    Text("This month!")
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
                Text("Best months")
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
                Text("Fertilizing")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if species.intelligence.shouldFertilizeThisMonth() {
                    Text("This month!")
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
                Text("This species rarely needs fertilizer!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Text("Best months")
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
                Text("Harvest")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if species.intelligence.isHarvestTime() {
                    Text("Harvest time!")
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
                    Text("Harvest months")
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
                    Text("Years to first harvest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()

                    if let age = plantAge {
                        if age >= years {
                            Text("Should be bearing! 🎉")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        } else {
                            Text("\(years - age) more year\(years - age == 1 ? "" : "s")")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text("~\(years) years")
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
                Text("Environment")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            envRow(icon: "sun.max.fill", label: "Sun", value: species.intelligence.sunExposure)
            envRow(icon: "thermometer.snowflake", label: "Frost hardiness", value: "\(species.intelligence.frostHardiness)°C")
            envRow(icon: "drop.halffull", label: "Ideal soil pH", value: species.intelligence.idealSoilPH)
            envRow(icon: "arrow.up.to.line", label: "Mature height", value: species.intelligence.matureHeight)
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
                Text("Watch Out For")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            if !species.intelligence.commonPests.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pests")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(species.intelligence.commonPests.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !species.intelligence.commonDiseases.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Diseases")
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
                title: "Time to prune!",
                subtitle: "This month is ideal for pruning \(species.name)"
            ))
        }
        if intel.shouldFertilizeThisMonth() {
            alerts.append(AlertItem(
                icon: "leaf.arrow.circlepath", color: .brown,
                title: "Time to fertilize!",
                subtitle: intel.fertilizerType.prefix(60) + "..."
            ))
        }
        if intel.isHarvestTime() {
            alerts.append(AlertItem(
                icon: "basket.fill", color: .orange,
                title: "Harvest time! 🎉",
                subtitle: "\(species.name) is ready to harvest"
            ))
        }
        return alerts
    }

    private var currentSeasonName: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:  return "Spring"
        case 6...8:  return "Summer"
        case 9...11: return "Autumn"
        default:     return "Winter"
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
