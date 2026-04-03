import SwiftUI

// MARK: - Garden Map View
// A zoomable, scrollable bird's-eye view of your garden with a snap-to-grid system.
//
// How it works:
// - The garden is a LARGE canvas (bigger than the screen) divided into a grid
// - Each grid cell is one "slot" where a plant can sit
// - When you drag a plant and drop it, it SNAPS to the nearest grid cell
// - You can PINCH TO ZOOM in/out, or use +/- buttons
// - You can SCROLL around the canvas to see all areas
// - TAP a plant to open its detail card
//
// Key concepts:
// - ScrollView: lets you pan around a canvas bigger than the screen
// - MagnificationGesture: detects pinch-to-zoom finger movements
// - "Snap to grid": round the drop position to the nearest grid cell
//   This keeps the garden looking neat and organized.
// - Canvas vs Screen: the garden canvas might be 1500x1500 points,
//   but your screen is only ~390x844. ScrollView handles the difference.

// MARK: - Grid Configuration
// These constants define how the grid looks and behaves.
// Changing these changes the entire garden layout.

private enum GridConfig {
    static let columns: Int = 16          // number of grid cells horizontally
    static let rows: Int = 20             // number of grid cells vertically
    static let baseCellSize: CGFloat = 70 // size of each grid cell in points
    static let minZoom: CGFloat = 0.5     // how far out you can zoom (50%)
    static let maxZoom: CGFloat = 2.5     // how close you can zoom (250%)
    static let zoomStep: CGFloat = 0.25   // how much +/- buttons change zoom
}

struct GardenMapView: View {

    // Access the shared plant store
    @Environment(PlantStore.self) private var store

    // MARK: - State

    // Zoom level: 1.0 = normal, 0.5 = zoomed out, 2.0 = zoomed in
    @State private var zoomScale: CGFloat = 0.8

    // Pinch gesture tracking
    @State private var lastZoomScale: CGFloat = 0.8

    // Which plant is currently being dragged
    @State private var draggingPlantID: UUID?

    // Current drag offset in pixels
    @State private var dragOffset: CGSize = .zero

    // Navigation: which plant to open in detail
    @State private var selectedPlant: Plant?

    // Controls the "Add Plant" sheet
    @State private var showingAddPlant: Bool = false

    // Show/hide grid lines (toggle in toolbar)
    @State private var showGrid: Bool = true

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            ZStack {
                // Main scrollable + zoomable garden
                gardenScrollView

                // Zoom controls overlay (bottom right)
                zoomControlsOverlay
            }
            .background(Color(red: 0.15, green: 0.35, blue: 0.15))
            .navigationTitle("Garden Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Left: grid toggle
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showGrid.toggle()
                        }
                    } label: {
                        Image(systemName: showGrid ? "grid" : "grid.circle")
                            .foregroundStyle(showGrid ? .blue : .secondary)
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
            .navigationDestination(item: $selectedPlant) { selected in
                if let index = store.plants.firstIndex(where: { $0.id == selected.id }) {
                    PlantDetailView(plant: $store.plants[index])
                }
            }
        }
    }

    // MARK: - Canvas Size
    // The total size of the garden canvas (in points).
    // This is usually BIGGER than the screen — that's why we need ScrollView.

    private var canvasWidth: CGFloat {
        CGFloat(GridConfig.columns) * GridConfig.baseCellSize * zoomScale
    }

    private var canvasHeight: CGFloat {
        CGFloat(GridConfig.rows) * GridConfig.baseCellSize * zoomScale
    }

    // Actual cell size at current zoom level
    private var cellSize: CGFloat {
        GridConfig.baseCellSize * zoomScale
    }

    // MARK: - Garden ScrollView
    // The main scrollable area containing the grid and all plants.

    private var gardenScrollView: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            ZStack(alignment: .topLeading) {
                // Layer 1: Garden background with grid
                gardenCanvas

                // Layer 2: Plants on top
                ForEach(store.plants) { plant in
                    if let index = store.plants.firstIndex(where: { $0.id == plant.id }) {
                        plantMarker(plant: plant, index: index)
                    }
                }

                // Empty state
                if store.plants.isEmpty {
                    emptyGardenOverlay
                        .frame(width: canvasWidth, height: canvasHeight)
                }
            }
            .frame(width: canvasWidth, height: canvasHeight)
            // Pinch to zoom gesture on the whole canvas
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let newScale = lastZoomScale * value
                        zoomScale = min(GridConfig.maxZoom, max(GridConfig.minZoom, newScale))
                    }
                    .onEnded { _ in
                        lastZoomScale = zoomScale
                    }
            )
        }
    }

    // MARK: - Garden Canvas
    // The green background with grid lines drawn using Canvas (very efficient).

    private var gardenCanvas: some View {
        Canvas { context, size in
            // 1. Fill background with grass green
            let bgRect = CGRect(origin: .zero, size: size)
            context.fill(
                Path(bgRect),
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.22, green: 0.52, blue: 0.22),
                        Color(red: 0.28, green: 0.60, blue: 0.28),
                        Color(red: 0.20, green: 0.48, blue: 0.20)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )

            guard showGrid else { return }

            let cell = cellSize

            // 2. Draw minor grid lines (thin, subtle)
            for col in 0...GridConfig.columns {
                let x = CGFloat(col) * cell
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.white.opacity(0.08)), lineWidth: 0.5)
            }

            for row in 0...GridConfig.rows {
                let y = CGFloat(row) * cell
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white.opacity(0.08)), lineWidth: 0.5)
            }

            // 3. Draw major grid lines every 4 cells (thicker, more visible)
            for col in stride(from: 0, through: GridConfig.columns, by: 4) {
                let x = CGFloat(col) * cell
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.white.opacity(0.15)), lineWidth: 1)
            }

            for row in stride(from: 0, through: GridConfig.rows, by: 4) {
                let y = CGFloat(row) * cell
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white.opacity(0.15)), lineWidth: 1)
            }

            // 4. Draw dots at every grid intersection
            for col in 0...GridConfig.columns {
                for row in 0...GridConfig.rows {
                    let x = CGFloat(col) * cell
                    let y = CGFloat(row) * cell

                    // Bigger dots at major intersections (every 4 cells)
                    let isMajor = col % 4 == 0 && row % 4 == 0
                    let dotSize: CGFloat = isMajor ? 4 : 2
                    let dotOpacity: Double = isMajor ? 0.25 : 0.12

                    let dotRect = CGRect(
                        x: x - dotSize / 2,
                        y: y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )
                    context.fill(
                        Path(ellipseIn: dotRect),
                        with: .color(.white.opacity(dotOpacity))
                    )
                }
            }

            // 5. Border around the garden
            context.stroke(
                Path(bgRect),
                with: .color(Color.brown.opacity(0.5)),
                lineWidth: 4
            )
        }
        .frame(width: canvasWidth, height: canvasHeight)
    }

    // MARK: - Plant Marker
    // A single plant icon on the map. Supports tap and long-press-drag.

    private func plantMarker(plant: Plant, index: Int) -> some View {
        let gridPos = plantGridPosition(plant: plant, index: index)
        let pixelPos = gridToPixel(col: gridPos.col, row: gridPos.row)

        let isDragging = draggingPlantID == plant.id
        let displayX = isDragging ? pixelPos.x + dragOffset.width : pixelPos.x
        let displayY = isDragging ? pixelPos.y + dragOffset.height : pixelPos.y

        // Marker size scales with zoom
        let markerSize: CGFloat = min(cellSize * 0.75, 56)
        let fontSize: CGFloat = min(cellSize * 0.15, 11)

        return VStack(spacing: 1) {
            ZStack {
                // Glow behind
                Circle()
                    .fill(plant.needsWatering ? .red.opacity(0.35) : .black.opacity(0.2))
                    .frame(width: markerSize + 6, height: markerSize + 6)

                // Plant circle
                if let photoID = plant.photoID,
                   let image = PhotoManager.shared.load(id: photoID) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: markerSize, height: markerSize)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                } else {
                    Image(systemName: plant.type.icon)
                        .font(.system(size: markerSize * 0.4))
                        .foregroundStyle(.white)
                        .frame(width: markerSize, height: markerSize)
                        .background(plant.type.color.gradient)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                }

                // Watering indicator
                if plant.needsWatering {
                    Circle()
                        .fill(.red)
                        .frame(width: markerSize * 0.28, height: markerSize * 0.28)
                        .overlay(
                            Image(systemName: "drop.fill")
                                .font(.system(size: markerSize * 0.14))
                                .foregroundStyle(.white)
                        )
                        .offset(x: markerSize * 0.38, y: -markerSize * 0.38)
                }
            }

            // Name label (hide when very zoomed out to reduce clutter)
            if zoomScale >= 0.6 {
                Text(plant.name)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.black.opacity(0.55))
                    .clipShape(Capsule())
            }
        }
        .position(x: displayX, y: displayY)
        .scaleEffect(isDragging ? 1.15 : 1.0)
        .shadow(color: isDragging ? .white.opacity(0.4) : .clear, radius: 8)
        .zIndex(isDragging ? 100 : 0)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
        // Tap → open detail
        .onTapGesture {
            selectedPlant = plant
        }
        // Long press + drag → move plant, snaps to grid on release
        .gesture(
            LongPressGesture(minimumDuration: 0.3)
                .sequenced(before: DragGesture())
                .onChanged { value in
                    switch value {
                    case .second(true, let drag):
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
                        if let drag = drag {
                            // Calculate the new pixel position
                            let newX = pixelPos.x + drag.translation.width
                            let newY = pixelPos.y + drag.translation.height

                            // SNAP TO GRID: convert pixel → nearest grid cell
                            let snappedCol = round(newX / cellSize)
                            let snappedRow = round(newY / cellSize)

                            // Clamp to grid bounds (0 to columns/rows)
                            let clampedCol = max(0, min(CGFloat(GridConfig.columns - 1), snappedCol))
                            let clampedRow = max(0, min(CGFloat(GridConfig.rows - 1), snappedRow))

                            // Save as grid coordinates (stored in gardenX/gardenY)
                            var updated = plant
                            updated.gardenX = Double(clampedCol)
                            updated.gardenY = Double(clampedRow)
                            store.update(updated)
                        }
                    default:
                        break
                    }
                    draggingPlantID = nil
                    dragOffset = .zero
                }
        )
    }

    // MARK: - Grid Position Helpers
    // Convert between grid coordinates (col, row) and pixel positions.

    // Get the grid position for a plant (from saved data or auto-layout)
    private func plantGridPosition(plant: Plant, index: Int) -> (col: CGFloat, row: CGFloat) {
        if let x = plant.gardenX, let y = plant.gardenY {
            return (col: CGFloat(x), row: CGFloat(y))
        }

        // Auto-place: arrange in rows with some spacing
        let cols = GridConfig.columns - 2  // leave 1-cell margin on each side
        let col = (index % cols) + 1       // start at column 1
        let row = (index / cols) + 1       // start at row 1

        return (col: CGFloat(col), row: CGFloat(row))
    }

    // Convert grid cell (col, row) to pixel position on canvas
    private func gridToPixel(col: CGFloat, row: CGFloat) -> CGPoint {
        CGPoint(
            x: (col + 0.5) * cellSize,  // +0.5 = center of the cell
            y: (row + 0.5) * cellSize
        )
    }

    // MARK: - Zoom Controls Overlay
    // +/- buttons floating in the bottom right corner.
    // These are always visible on top of the scrollview.

    private var zoomControlsOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 0) {
                    // Zoom in button
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            zoomScale = min(GridConfig.maxZoom, zoomScale + GridConfig.zoomStep)
                            lastZoomScale = zoomScale
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(zoomScale >= GridConfig.maxZoom)

                    Divider()
                        .frame(width: 30)

                    // Zoom percentage label
                    Text("\(Int(zoomScale * 100))%")
                        .font(.caption2.weight(.medium))
                        .frame(width: 44, height: 28)
                        .foregroundStyle(.secondary)

                    Divider()
                        .frame(width: 30)

                    // Zoom out button
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            zoomScale = max(GridConfig.minZoom, zoomScale - GridConfig.zoomStep)
                            lastZoomScale = zoomScale
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.title3.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(zoomScale <= GridConfig.minZoom)

                    Divider()
                        .frame(width: 30)

                    // Fit-all button (resets zoom to fit everything)
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            zoomScale = 0.8
                            lastZoomScale = 0.8
                        }
                    } label: {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.caption.weight(.semibold))
                            .frame(width: 44, height: 40)
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                .padding(.trailing, 12)
                .padding(.bottom, 16)
            }
        }
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
