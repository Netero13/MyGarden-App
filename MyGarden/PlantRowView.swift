import SwiftUI

// MARK: - Plant Row View
// This is a single row in the plant list.
// Think of it as a "card" that shows one plant's key info at a glance.
// It's a reusable piece — the list will show many of these stacked vertically.

struct PlantRowView: View {

    // The plant to display. 'let' means it can't be changed — this view only SHOWS data.
    let plant: Plant

    // Cache the loaded photo so we don't reload it every time the row redraws
    @State private var photo: UIImage?

    var body: some View {
        HStack(spacing: 12) {

            // -- Left: Photo or Type Icon --
            // If the plant has a photo, show it. Otherwise show the colored type icon.
            if let photo = photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: plant.type.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(plant.type.color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

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
                Label(NSLocalizedString("Needs water", comment: ""), systemImage: "drop.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .labelStyle(.iconOnly)
            } else {
                Label(NSLocalizedString("Watered", comment: ""), systemImage: "drop.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .labelStyle(.iconOnly)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            // Load photo from disk when the row appears on screen
            if let photoID = plant.photoID {
                photo = PhotoManager.shared.load(id: photoID)
            }
        }
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
