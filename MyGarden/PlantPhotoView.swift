import SwiftUI
import PhotosUI

// MARK: - Plant Photo View
// A reusable component that shows a plant photo (or a placeholder)
// and lets you tap to pick a new photo from your library.
//
// Key SwiftUI concept: PhotosPicker
// Apple provides a built-in photo picker that's safe and private.
// The user picks a photo, and we receive it — we never access the
// full photo library, only what the user explicitly selects.

struct PlantPhotoView: View {

    // The photo ID stored in the model (nil = no photo yet)
    let photoID: String?

    // Size of the photo view
    var size: CGFloat = 100

    // Whether tapping shows a picker
    var editable: Bool = false

    // Called when user picks a new photo — returns the new photo ID
    var onPhotoSelected: ((String) -> Void)?

    // PhotosPicker state
    @State private var selectedItem: PhotosPickerItem?
    @State private var loadedImage: UIImage?

    var body: some View {
        Group {
            if let image = loadedImage {
                // Show the photo
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size > 60 ? 16 : 10))
            } else {
                // Placeholder when no photo exists
                ZStack {
                    RoundedRectangle(cornerRadius: size > 60 ? 16 : 10)
                        .fill(.secondary.opacity(0.15))
                        .frame(width: size, height: size)

                    Image(systemName: editable ? "camera.fill" : "leaf.fill")
                        .font(size > 60 ? .title : .caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // Small camera badge when editable
            if editable {
                Image(systemName: "camera.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white, .blue)
                    .offset(x: 4, y: 4)
            }
        }
        // Wrap in PhotosPicker if editable
        .overlay {
            if editable {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    Color.clear
                        .frame(width: size, height: size)
                }
            }
        }
        // Load photo on appear
        .onAppear {
            if let photoID = photoID {
                loadedImage = PhotoManager.shared.load(id: photoID)
            }
        }
        // When user picks a new photo from the library
        .onChange(of: selectedItem) {
            Task {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    // Save the photo and get an ID
                    if let newID = PhotoManager.shared.save(uiImage) {
                        loadedImage = uiImage
                        onPhotoSelected?(newID)
                    }
                }
            }
        }
    }
}

// MARK: - Small Photo Thumbnail
// A simpler version for use in list rows — just shows the photo, no editing.

struct PlantPhotoThumbnail: View {
    let photoID: String?
    var size: CGFloat = 44

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                // No photo — return nil so the caller can show the default icon
                EmptyView()
            }
        }
        .onAppear {
            if let photoID = photoID {
                image = PhotoManager.shared.load(id: photoID)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PlantPhotoView(photoID: nil, size: 120, editable: true)
        PlantPhotoView(photoID: nil, size: 60, editable: false)
    }
}
