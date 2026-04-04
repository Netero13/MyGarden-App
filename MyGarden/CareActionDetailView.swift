import SwiftUI
import PhotosUI

// MARK: - Care Action Detail View
// Opens when you tap a care task in "Smart Care" on the dashboard,
// or from the plant detail page's "Care Due This Month" section.
//
// This is the "intelligence page" — it tells you EXACTLY what to do,
// when, and why, for a specific care action on a specific plant.
//
// Example: You tap "Pest Treatment — Cherry" and see:
// - What pests to watch for (aphids, cherry fruit fly, etc.)
// - What treatment to apply (copper sulfate before bud break...)
// - Which months to treat (March, May, July)
// - Your tree's age and how it affects care
// - Optional photo + note (like Log Activity)
// - A "Mark as Done" button at the bottom

struct CareActionDetailView: View {

    let plant: Plant
    let action: CareAction
    let species: PlantSpecies

    @Environment(PlantStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    // Photo + note state — user can optionally attach these when marking as done
    @State private var selectedPhoto: UIImage?
    @State private var savedPhotoID: String?
    @State private var note: String = ""

    private var intel: TreeIntelligence { species.intelligence }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // -- Header --
                headerSection

                // -- Main recommendation card --
                recommendationCard

                // -- Schedule card (which months) --
                scheduleCard

                // -- Extra context (pests list, diseases list, age info) --
                contextCard

                // -- Seasonal tip --
                seasonalTipCard

                // -- Photo + Note section (before "Mark as Done") --
                if !isDone {
                    photoAndNoteSection
                }

                // -- Mark as Done button --
                if !isDone {
                    doneButton
                } else {
                    alreadyDoneLabel
                }
            }
            .padding()
        }
        .navigationTitle(action.localizedLabel)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Big action icon
            Image(systemName: action.icon)
                .font(.largeTitle)
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(action.color.gradient)
                .clipShape(Circle())

            // Action name
            Text(action.localizedLabel)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(action.color)

            // Plant name + age
            Text(plant.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(plant.ageLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Recommendation Card
    // The main advice — what to do and how

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text(NSLocalizedString("Recommendation", comment: ""))
                    .font(.headline)
                Spacer()
            }

            Divider()

            Text(mainRecommendation)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // The main advice text based on action type
    private var mainRecommendation: String {
        switch action {
        case .prune:
            return intel.pruningTips
        case .fertilize:
            return intel.fertilizerType
        case .harvest:
            if let years = intel.yearsToBearing {
                if plant.age >= years {
                    return String(format: NSLocalizedString("Your %@ is %lld years old and should be producing fruit. Check branches for ripe fruit and pick when ready.", comment: ""),
                                  species.name, plant.age)
                } else {
                    let remaining = years - plant.age
                    return String(format: NSLocalizedString("Your %@ is still young (%lld years old). Typically starts bearing fruit at %lld years — about %lld more year(s) to go.", comment: ""),
                                  species.name, plant.age, years, remaining)
                }
            }
            return String(format: NSLocalizedString("Your %@ is ready to harvest this month. Pick fruit when ripe.", comment: ""), species.name)
        case .pestTreatment:
            return intel.pestTreatmentTip
        case .diseaseTreatment:
            return intel.diseaseTreatmentTip
        }
    }

    // MARK: - Schedule Card
    // Which months this action is recommended

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(action.color)
                Text(NSLocalizedString("Schedule", comment: ""))
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Show months as colored chips
            let months = actionMonths
            if months.isEmpty {
                Text(NSLocalizedString("No specific schedule — apply as needed.", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Month chips in a flow layout
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 70), spacing: 8)
                ], spacing: 8) {
                    ForEach(months, id: \.self) { month in
                        let isCurrentMonth = month == Calendar.current.component(.month, from: Date())
                        Text(monthName(month))
                            .font(.caption)
                            .fontWeight(isCurrentMonth ? .bold : .regular)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(isCurrentMonth ? action.color.opacity(0.2) : Color.secondary.opacity(0.08))
                            .foregroundStyle(isCurrentMonth ? action.color : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isCurrentMonth ? action.color : Color.clear, lineWidth: 1.5)
                            )
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var actionMonths: [Int] {
        switch action {
        case .prune:            return intel.pruningMonths
        case .fertilize:        return intel.fertilizerMonths
        case .harvest:          return intel.harvestMonths ?? []
        case .pestTreatment:    return intel.pestTreatmentMonths
        case .diseaseTreatment: return intel.diseaseTreatmentMonths
        }
    }

    // MARK: - Context Card
    // Extra info: pest/disease lists, age-specific notes, environment tips

    @ViewBuilder
    private var contextCard: some View {
        let rows = contextRows
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text(NSLocalizedString("Details", comment: ""))
                        .font(.headline)
                    Spacer()
                }

                Divider()

                ForEach(rows, id: \.title) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(row.color)

                        Text(row.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if row.title != rows.last?.title {
                        Divider()
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private struct ContextRow: Hashable {
        let title: String
        let content: String
        let color: Color
    }

    private var contextRows: [ContextRow] {
        var rows: [ContextRow] = []

        switch action {
        case .pestTreatment:
            // Show common pests for this species
            if !intel.commonPests.isEmpty {
                rows.append(ContextRow(
                    title: NSLocalizedString("Common Pests", comment: ""),
                    content: intel.commonPests.joined(separator: " · "),
                    color: .red
                ))
            }

        case .diseaseTreatment:
            // Show common diseases for this species
            if !intel.commonDiseases.isEmpty {
                rows.append(ContextRow(
                    title: NSLocalizedString("Common Diseases", comment: ""),
                    content: intel.commonDiseases.joined(separator: " · "),
                    color: .purple
                ))
            }

        case .prune:
            // Age-specific pruning advice
            if plant.age < 3 {
                rows.append(ContextRow(
                    title: NSLocalizedString("Young Tree Note", comment: ""),
                    content: NSLocalizedString("Young trees need formative pruning to shape the crown. Focus on structure, not heavy cutting.", comment: ""),
                    color: .orange
                ))
            } else if plant.age >= 7 {
                rows.append(ContextRow(
                    title: NSLocalizedString("Established Tree Note", comment: ""),
                    content: NSLocalizedString("Established trees need maintenance pruning. Remove dead, crossing, and diseased branches.", comment: ""),
                    color: .green
                ))
            }

        case .fertilize:
            // Age-specific fertilizer advice
            if plant.age < intel.yearsToMature {
                rows.append(ContextRow(
                    title: NSLocalizedString("Young Tree Note", comment: ""),
                    content: NSLocalizedString("Young trees need more nitrogen for growth. Apply at half the mature rate to avoid burning roots.", comment: ""),
                    color: .green
                ))
            }

            // Soil info
            rows.append(ContextRow(
                title: NSLocalizedString("Soil", comment: ""),
                content: String(format: NSLocalizedString("Ideal pH: %@ · %@", comment: ""),
                                intel.idealSoilPH, intel.sunExposure),
                color: .brown
            ))

        case .harvest:
            if let years = intel.yearsToBearing {
                if plant.age < years {
                    rows.append(ContextRow(
                        title: NSLocalizedString("Not Ready Yet", comment: ""),
                        content: String(format: NSLocalizedString("This species typically starts bearing fruit at %lld years. Your tree is %lld years old.", comment: ""),
                                        years, plant.age),
                        color: .orange
                    ))
                }
            }
        }

        return rows
    }

    // MARK: - Seasonal Tip Card

    private var seasonalTipCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: seasonIcon)
                    .foregroundStyle(seasonColor)
                Text(NSLocalizedString("Seasonal Tip", comment: ""))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Text(intel.currentSeasonTip())
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(seasonColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Done Button

    private var isDone: Bool {
        switch action {
        case .prune:            return plant.wasDoneThisMonth(.pruned)
        case .fertilize:        return plant.wasDoneThisMonth(.fertilized)
        case .harvest:          return plant.wasDoneThisMonth(.harvested)
        case .pestTreatment:    return plant.wasDoneThisMonth(.pestControl)
        case .diseaseTreatment: return plant.wasDoneThisMonth(.diseaseControl)
        }
    }

    // MARK: - Photo & Note Section
    // Same UX as the "Log Activity" form — optional photo + optional note.
    // Attached to the activity when user taps "Mark as Done".

    private var photoAndNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundStyle(.secondary)
                Text(NSLocalizedString("Add Details (optional)", comment: ""))
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Photo preview + remove button
            if let photo = selectedPhoto {
                HStack {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Spacer()

                    Button(role: .destructive) {
                        if let id = savedPhotoID {
                            PhotoManager.shared.delete(id: id)
                        }
                        selectedPhoto = nil
                        savedPhotoID = nil
                    } label: {
                        Label(NSLocalizedString("Remove", comment: ""), systemImage: "xmark.circle.fill")
                            .font(.caption)
                    }
                }
            }

            // Camera + Library options (reusable component)
            PhotoSourcePicker { image in
                if let oldID = savedPhotoID {
                    PhotoManager.shared.delete(id: oldID)
                }
                selectedPhoto = image
                savedPhotoID = PhotoManager.shared.save(image)
            }

            Divider()

            // Note field
            TextField(NSLocalizedString("Optional notes...", comment: ""), text: $note, axis: .vertical)
                .lineLimit(2...4)
                .font(.subheadline)

            Text(NSLocalizedString("e.g. \"applied copper fungicide\" or \"spotted aphids on lower branches\"", comment: ""))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var doneButton: some View {
        Button {
            let noteText = note.isEmpty ? nil : note
            switch action {
            case .prune:            store.prune(id: plant.id, note: noteText, photoID: savedPhotoID)
            case .fertilize:        store.fertilize(id: plant.id, note: noteText, photoID: savedPhotoID)
            case .harvest:          store.harvest(id: plant.id, note: noteText, photoID: savedPhotoID)
            case .pestTreatment:    store.treatPests(id: plant.id, note: noteText, photoID: savedPhotoID)
            case .diseaseTreatment: store.treatDiseases(id: plant.id, note: noteText, photoID: savedPhotoID)
            }
            dismiss()
        } label: {
            Label(NSLocalizedString("Mark as Done", comment: ""), systemImage: "checkmark.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(action.color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 8)
    }

    private var alreadyDoneLabel: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Text(NSLocalizedString("Done this month!", comment: ""))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        return formatter.monthSymbols[month - 1]
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
