import Foundation
import SwiftUI
import PhotosUI

// MARK: - Photo Manager
// Handles saving and loading photos to/from the phone's storage.
//
// Why not store photos in JSON?
// Photos are BIG (several MB each). If we put them in the JSON file,
// loading your plant list would be very slow. Instead, we save each photo
// as a separate file and just store the filename (a UUID string) in the model.
//
// Think of it like: the JSON file is a spreadsheet, and photos are attachments
// stored in a folder next to it.

class PhotoManager {

    // Singleton — one shared instance used throughout the app.
    // "Singleton" means there's only ONE PhotoManager, and everyone uses it.
    static let shared = PhotoManager()

    // The folder where photos are saved
    private let photosDirectory: URL

    private init() {
        // Create a "PlantPhotos" folder inside the app's Documents directory
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        photosDirectory = documents.appendingPathComponent("PlantPhotos")

        // Create the folder if it doesn't exist yet
        if !FileManager.default.fileExists(atPath: photosDirectory.path) {
            try? FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Save a Photo
    // Takes a UIImage, compresses it to JPEG, saves it, and returns a unique ID.
    // The ID is what we store in our Plant/CareActivity model.
    func save(_ image: UIImage) -> String? {
        let id = UUID().uuidString

        // Compress to JPEG at 70% quality — good balance of quality vs file size
        // A 12MP photo goes from ~5MB to ~500KB
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }

        let fileURL = photosDirectory.appendingPathComponent("\(id).jpg")

        do {
            try data.write(to: fileURL)
            return id
        } catch {
            print("❌ Failed to save photo: \(error)")
            return nil
        }
    }

    // MARK: - Load a Photo
    // Given a photo ID, loads it from disk and returns a UIImage.
    func load(id: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent("\(id).jpg")
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Delete a Photo
    // Removes the photo file from disk. Called when deleting a plant.
    func delete(id: String) {
        let fileURL = photosDirectory.appendingPathComponent("\(id).jpg")
        try? FileManager.default.removeItem(at: fileURL)
    }
}
