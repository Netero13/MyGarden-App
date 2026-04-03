import SwiftUI
import PhotosUI

// MARK: - Photo Source Picker
// A reusable component that shows two options:
//   📷 "Take Photo" — opens the camera
//   🖼️ "Choose from Library" — opens the photo library
//
// On Simulator (no camera), only the library option appears.
// On a real iPhone, both options appear.

struct PhotoSourcePicker: View {

    // Called when a photo is selected (from either source)
    var onPhotoPicked: (UIImage) -> Void

    // State
    @State private var showingCamera = false
    @State private var showingLibrary = false
    @State private var selectedItem: PhotosPickerItem?

    // Check if the device has a camera (Simulator doesn't)
    private var hasCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        Group {
            // Camera button — only shown on real devices
            if hasCamera {
                Button {
                    showingCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                }
            }

            // Library picker
            PhotosPicker(
                selection: $selectedItem,
                matching: .images
            ) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
        }
        // Camera sheet
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView { image in
                showingCamera = false
                onPhotoPicked(image)
            } onCancel: {
                showingCamera = false
            }
            .ignoresSafeArea()
        }
        // Library selection handler
        .onChange(of: selectedItem) {
            Task {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    onPhotoPicked(uiImage)
                }
                selectedItem = nil
            }
        }
    }
}

#Preview {
    List {
        PhotoSourcePicker { image in
            print("Got photo: \(image.size)")
        }
    }
}
