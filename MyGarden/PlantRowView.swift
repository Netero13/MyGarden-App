import SwiftUI

// MARK: - Plant Row View
// This is a single row in the plant list.
// Think of it as a "card" that shows one plant's key info at a glance.
// It's a reusable piece — the list will show many of these stacked vertically.

struct PlantRowView: View {

    // The plant to display. 'let' means it can't be changed — this view only SHOWS data.
    let plant: Plant

    var body: some View {
        HStack(spacing: 12) {

            // -- Left: Type Icon --
            // A colored circle with the plant type's icon inside.
            // This makes it easy to visually scan what type each plant is.
            Image(systemName: plant.type.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(plant.type.color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // -- Middle: Name & Variety --
            // VStack = Vertical Stack — puts things on top of each other.
            // The name is big, the variety is smaller and gray underneath.
            VStack(alignment: .leading, spacing: 3) {
                Text(plant.name)
                    .font(.headline)

                if let variety = plant.variety {
                    Text(variety)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Spacer pushes everything after it to the right edge
            Spacer()

            // -- Right: Watering Status --
            // Shows a droplet icon:
            //   🔴 Red = needs watering now (overdue or never watered)
            //   🔵 Blue = watered recently, all good
            if plant.needsWatering {
                Label("Needs water", systemImage: "drop.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .labelStyle(.iconOnly)
            } else {
                Label("Watered", systemImage: "drop.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .labelStyle(.iconOnly)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
// This lets you see the row in Xcode's preview canvas without running the app.
// We show two examples: one that needs water, one that doesn't.

#Preview("Needs Watering") {
    PlantRowView(plant: Plant.samples[1]) // Tomato — overdue
        .padding()
}

#Preview("Recently Watered") {
    PlantRowView(plant: Plant.samples[2]) // Sunflower — just watered
        .padding()
}
