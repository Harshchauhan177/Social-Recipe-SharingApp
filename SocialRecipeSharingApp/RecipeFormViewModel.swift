import Combine
import Foundation
import Supabase

@MainActor
final class RecipeFormViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var imageURL = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.shared.client

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
            let payload = RecipeInsert(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                image_url: imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : imageURL,
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
        errorMessage = nil
        isLoading = false
    }
}
