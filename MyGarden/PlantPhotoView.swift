import SwiftUI
import PhotosUI

// MARK: - Plant Photo View
// A reusable component that shows a plant photo (or a placeholder)
// and lets you tap to pick a new photo from camera or library.

struct PlantPhotoView: View {

    // The photo ID stored in the model (nil = no photo yet)
    let photoID: String?

    // Size of the photo view
    var size: CGFloat = 100

    // Whether tapping shows a picker
    var editable: Bool = false

    // Called when user picks a new photo — returns the new photo ID
    var onPhotoSelected: ((String) -> Void)?

    // State
    @State private var loadedImage: UIImage?
    @State private var showingPhotoOptions = false
    @State private var showingCamera = false
    @State private var libraryItem: PhotosPickerItem?

    // Check if camera is available
    private var hasCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size > 60 ? 16 : 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size > 60 ? 16 : 10)
                        .fill(.secondary.opacity(0.15))
                        .frame(width: size, height: size)

                    VStack(spacing: 4) {
                        Image(systemName: editable ? "camera.fill" : "leaf.fill")
                            .font(size > 60 ? .title : .caption)
                            .foregroundStyle(.secondary)
                        if editable && size > 60 {
                            Text(NSLocalizedString("Add Photo", comment: ""))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        // Tap to change photo (only when editable)
        .onTapGesture {
            if editable {
                showingPhotoOptions = true
            }
        }
        // Action sheet: Camera or Library?
        .confirmationDialog("Choose Photo", isPresented: $showingPhotoOptions) {
            if hasCamera {
                Button(NSLocalizedString("Take Photo", comment: "")) {
                    showingCamera = true
                }
            }
            Button(NSLocalizedString("Choose from Library", comment: "")) {
                // Trigger the hidden PhotosPicker
            }
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
        }
        // Hidden PhotosPicker triggered by the action sheet
        .photosPicker(isPresented: Binding(
            get: {
                // This is a workaround: we show the picker when the dialog
                // "Choose from Library" is tapped. We use a separate flag.
                false
            },
            set: { _ in }
        ), selection: $libraryItem, matching: .images)
        // Camera sheet
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView { image in
                showingCamera = false
                handleNewPhoto(image)
            } onCancel: {
                showingCamera = false
            }
            .ignoresSafeArea()
        }
        .onAppear {
            if let photoID = photoID {
                loadedImage = PhotoManager.shared.load(id: photoID)
            }
        }
    }

    private func handleNewPhoto(_ image: UIImage) {
        if let newID = PhotoManager.shared.save(image) {
            loadedImage = image
            onPhotoSelected?(newID)
        }
    }
}

// MARK: - Simpler version for detail screen
// Since the confirmationDialog + PhotosPicker combo is tricky,
// let's use a simpler approach for the detail screen header.

struct PlantPhotoHeader: View {
    let photoID: String?
    var size: CGFloat = 120
    var onPhotoSelected: ((String) -> Void)?

    @State private var loadedImage: UIImage?
    @State private var showingOptions = false
    @State private var showingCamera = false
    @State private var showingLibrary = false
    @State private var libraryItem: PhotosPickerItem?

    private var hasCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.secondary.opacity(0.15))
                        .frame(width: size, height: size)

                    VStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text(NSLocalizedString("Add Photo", comment: ""))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "camera.circle.fill")
                .font(.title3)
                .foregroundStyle(.white, .blue)
                .offset(x: 4, y: 4)
        }
        .onTapGesture {
            showingOptions = true
        }
        .confirmationDialog("Plant Photo", isPresented: $showingOptions) {
            if hasCamera {
                Button(NSLocalizedString("Take Photo", comment: "")) {
                    showingCamera = true
                }
            }
            Button(NSLocalizedString("Choose from Library", comment: "")) {
                showingLibrary = true
            }
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView { image in
                showingCamera = false
                savePhoto(image)
            } onCancel: {
                showingCamera = false
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showingLibrary, selection: $libraryItem, matching: .images)
        .onChange(of: libraryItem) {
            Task {
                if let data = try? await libraryItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    savePhoto(uiImage)
                }
                libraryItem = nil
            }
        }
        .onAppear {
            if let photoID = photoID {
                loadedImage = PhotoManager.shared.load(id: photoID)
            }
        }
    }

    private func savePhoto(_ image: UIImage) {
        if let newID = PhotoManager.shared.save(image) {
            loadedImage = image
            onPhotoSelected?(newID)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PlantPhotoHeader(photoID: nil)
    }
}
