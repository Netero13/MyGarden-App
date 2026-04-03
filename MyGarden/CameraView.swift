import SwiftUI
import UIKit

// MARK: - Camera View
// SwiftUI doesn't have a built-in camera component, so we wrap UIKit's
// UIImagePickerController in a SwiftUI-compatible wrapper.
//
// Key concept: UIViewControllerRepresentable
// This is a "bridge" between UIKit (the old iOS framework) and SwiftUI (the new one).
// Some features like the camera still live in UIKit, so we need this bridge
// to use them in our SwiftUI app.

struct CameraView: UIViewControllerRepresentable {

    // Called when user takes a photo — sends the image back
    var onPhotoTaken: (UIImage) -> Void

    // Called when user cancels
    var onCancel: () -> Void

    // Create the camera controller
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    // Required but we don't need to update anything
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    // The Coordinator handles callbacks from the camera
    func makeCoordinator() -> Coordinator {
        Coordinator(onPhotoTaken: onPhotoTaken, onCancel: onCancel)
    }

    // MARK: - Coordinator
    // Acts as the "delegate" — UIKit's way of sending events back to us.
    // When the user takes a photo or taps cancel, these methods are called.

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPhotoTaken: (UIImage) -> Void
        let onCancel: () -> Void

        init(onPhotoTaken: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onPhotoTaken = onPhotoTaken
            self.onCancel = onCancel
        }

        // User took a photo
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onPhotoTaken(image)
            }
        }

        // User tapped cancel
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
