import Combine
import Foundation
import Supabase
import UIKit

@MainActor
final class RecipeFormViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var imageURL = ""
    @Published var pickedImageData: Data?
    @Published var pickedImagePreview: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.shared.client
    private let bucket = "recipes" // ensure this bucket exists and is public

    var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func submit(userId: UUID) async -> Bool {
        guard canSubmit else {
            errorMessage = "Title and description are required."
            return false
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            var finalImageURL: String? = nil
            if let data = pickedImageData {
                finalImageURL = try await uploadImage(data: data)
            } else {
                let trimmed = imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
                finalImageURL = trimmed.isEmpty ? nil : trimmed
            }

            let payload = RecipeInsert(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                image_url: finalImageURL,
                user_id: userId
            )
            try await client
                .from("recipes")
                .insert(payload)
                .execute()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func reset() {
        title = ""
        description = ""
        imageURL = ""
        pickedImageData = nil
        pickedImagePreview = nil
        errorMessage = nil
        isLoading = false
    }

    private func uploadImage(data: Data) async throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let path = "user-\(UUID().uuidString)/\(fileName)"
        let options = FileOptions(contentType: "image/jpeg", upsert: false)
        _ = try await client.storage
            .from(bucket)
            .upload(
                path: path,
                file: data,
                options: options
            )
        let publicURL = try client.storage.from(bucket).getPublicURL(path: path)
        return publicURL.absoluteString
    }
}
