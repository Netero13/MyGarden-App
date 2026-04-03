import SwiftUI

// MARK: - Garden Map View
// A visual bird's-eye view of your garden!
// Plants appear as circular icons on a green canvas.
//
// How it works:
// - Each plant has gardenX/gardenY coordinates (0.0 to 1.0 = percentages)
// - We multiply those by the canvas size to get pixel positions
// - LONG PRESS + DRAG to move a plant to a new spot
// - TAP a plant to open its detail card
//
// Key SwiftUI concepts:
// - GeometryReader: tells us the exact size of the screen area so we can
//   position plants correctly on any device (iPhone SE, iPhone 15 Pro, iPad)
// - DragGesture: detects finger movement and updates position in real-time
// - ZStack: layers views on top of each other (garden background → plants on top)
// - NavigationLink: makes tapping a plant navigate to its detail screen

struct GardenMapView: View {

    // Access the shared plant store
    @Environment(PlantStore.self) private var store

    // Which plant is currently being dragged (nil = nothing being dragged)
    @State private var draggingPlantID: UUID?

    // Temporary offset while dragging (in pixels, not percentages)
    @State private var dragOffset: CGSize = .zero

    // Controls the "Add Plant" sheet
    @State private var showingAddPlant: Bool = false

    // The selected plant for navigation
    @State private var selectedPlant: Plant?

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            GeometryReader { geometry in
                let gardenSize = geometry.size

                ZStack {
                    // -- Background: green garden canvas --
                    gardenBackground(size: gardenSize)

                    // -- Plants: scattered on the canvas --
                    ForEach(store.plants) { plant in
                        if let index = store.plants.firstIndex(where: { $0.id == plant.id }) {
                            plantMarker(
                                plant: plant,
                                gardenSize: gardenSize,
                                index: index
                            )
                        }
                    }

                    // -- Empty state overlay --
                    if store.plants.isEmpty {
                        emptyGardenOverlay
                    }
                }
            }
            .navigationTitle("Garden Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Add plant button
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
            // Navigation to plant detail when tapped
            .navigationDestination(item: $selectedPlant) { selected in
                if let index = store.plants.firstIndex(where: { $0.id == selected.id }) {
                    PlantDetailView(plant: $store.plants[index])
                }
            }
        }
    }

    // MARK: - Garden Background
    // A nice green gradient with grid lines to look like a garden plot.

    private func gardenBackground(size: CGSize) -> some View {
        ZStack {
            // Base gradient — dark green to lighter green (like grass)
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.5, blue: 0.2),
                    Color(red: 0.3, green: 0.65, blue: 0.3),
                    Color(red: 0.25, green: 0.55, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle grid pattern — like garden bed rows
            // Horizontal lines
            VStack(spacing: 40) {
                ForEach(0..<20, id: \.self) { _ in
                    Rectangle()
                        .fill(.white.opacity(0.04))
                        .frame(height: 1)
                }
            }

            // Vertical lines
            HStack(spacing: 40) {
                ForEach(0..<15, id: \.self) { _ in
                    Rectangle()
                        .fill(.white.opacity(0.04))
                        .frame(width: 1)
                }
            }

            // Garden border — a nice earthy border around the edges
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(
                    Color.brown.opacity(0.4),
                    lineWidth: 6
                )

            // Hint text at the bottom
            VStack {
                Spacer()
                Text("Long press & drag to move plants")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 12)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Plant Marker
    // Each plant appears as a circular marker on the map.
    // Shows the plant's photo (or type icon if no photo).
    // Tap → open detail. Long press + drag → move it.

    private func plantMarker(plant: Plant, gardenSize: CGSize, index: Int) -> some View {

        // Calculate the pixel position from percentage coordinates
        // If plant has no position yet, auto-place it in a grid
        let pos = plantPosition(plant: plant, index: index, gardenSize: gardenSize)

        // Is this the plant currently being dragged?
        let isDragging = draggingPlantID == plant.id

        // Calculate display position (base + drag offset if dragging)
        let displayX = isDragging ? pos.x + dragOffset.width : pos.x
        let displayY = isDragging ? pos.y + dragOffset.height : pos.y

        return VStack(spacing: 2) {
            // Plant circle — photo or icon
            ZStack {
                // Shadow/glow behind the circle
                Circle()
                    .fill(plant.needsWatering ? .red.opacity(0.3) : .blue.opacity(0.2))
                    .frame(width: 58, height: 58)

                // The actual plant circle
                if let photoID = plant.photoID,
                   let image = PhotoManager.shared.load(id: photoID) {
                    // Has a photo — show it in a circle
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(.white, lineWidth: 2)
                        )
                } else {
                    // No photo — show type icon with colored background
                    Image(systemName: plant.type.icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(plant.type.color.gradient)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(.white, lineWidth: 2)
                        )
                }

                // Watering indicator dot (red = needs water)
                if plant.needsWatering {
                    Circle()
                        .fill(.red)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Image(systemName: "drop.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.white)
                        )
                        .offset(x: 20, y: -20)
                }
            }

            // Plant name label below the circle
            Text(plant.name)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.black.opacity(0.5))
                .clipShape(Capsule())
        }
        // Position the marker on the canvas
        .position(x: displayX, y: displayY)
        // Scale up slightly when being dragged (visual feedback)
        .scaleEffect(isDragging ? 1.2 : 1.0)
        // Bring dragged plant to front
        .zIndex(isDragging ? 100 : 0)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
        // TAP: navigate to plant detail
        .onTapGesture {
            selectedPlant = plant
        }
        // LONG PRESS + DRAG: move the plant on the map
        .gesture(
            LongPressGesture(minimumDuration: 0.3)
                .sequenced(before: DragGesture())
                .onChanged { value in
                    switch value {
                    case .second(true, let drag):
                        // Long press succeeded, now dragging
                        draggingPlantID = plant.id
                        if let drag = drag {
                            dragOffset = drag.translation
                        }
                    default:
                        break
                    }
                }
                .onEnded { value in
                    switch value {
                    case .second(true, let drag):
                        // Drag ended — calculate new position as percentage
                        if let drag = drag {
                            let newX = pos.x + drag.translation.width
                            let newY = pos.y + drag.translation.height

                            // Clamp to garden bounds (keep inside the canvas)
                            // We leave 30pt margin so the marker doesn't go off-screen
                            let clampedX = max(30, min(gardenSize.width - 30, newX))
                            let clampedY = max(30, min(gardenSize.height - 30, newY))

                            // Convert pixels back to percentage (0.0 to 1.0)
                            var updatedPlant = plant
                            updatedPlant.gardenX = clampedX / gardenSize.width
                            updatedPlant.gardenY = clampedY / gardenSize.height
                            store.update(updatedPlant)
                        }
                    default:
                        break
                    }

                    // Reset drag state
                    draggingPlantID = nil
                    dragOffset = .zero
                }
        )
    }

    // MARK: - Calculate Plant Position
    // Converts percentage coordinates to pixel positions.
    // If a plant has never been placed (nil coordinates), we auto-arrange
    // plants in a neat grid so they don't all stack on top of each other.

    private func plantPosition(plant: Plant, index: Int, gardenSize: CGSize) -> CGPoint {
        if let x = plant.gardenX, let y = plant.gardenY {
            // Plant has saved coordinates — convert percentage to pixels
            return CGPoint(
                x: x * gardenSize.width,
                y: y * gardenSize.height
            )
        }

        // No saved position — auto-place in a grid
        // We use the plant's index to calculate a grid position
        let columns = max(3, Int(gardenSize.width / 90))  // ~90pt per column
        let row = index / columns
        let col = index % columns

        // Calculate position with margins
        let marginX: CGFloat = 50
        let marginY: CGFloat = 50
        let spacingX = (gardenSize.width - marginX * 2) / CGFloat(max(columns - 1, 1))
        let spacingY: CGFloat = 90

        return CGPoint(
            x: marginX + CGFloat(col) * spacingX,
            y: marginY + CGFloat(row) * spacingY
        )
    }

    // MARK: - Empty Garden Overlay

    private var emptyGardenOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.7))

            Text("Your garden is empty")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.8))

            Text("Tap + to add your first plant!")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

// MARK: - Make Plant Hashable for navigationDestination
// navigationDestination(item:) needs the type to be Hashable.
// We hash by ID since each plant has a unique UUID.

extension Plant: Hashable {
    static func == (lhs: Plant, rhs: Plant) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview {
    GardenMapView()
        .environment(PlantStore())
}
