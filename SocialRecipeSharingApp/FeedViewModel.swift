import Combine
import Foundation
import Supabase

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var likeInProgress: Set<Int> = []
    @Published var likedRecipeIds: Set<Int> = []

    private let client = SupabaseManager.shared.client
    private let userId: UUID

    init(userId: UUID) {
        self.userId = userId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let data: [Recipe] = try await client
                .from("recipes")
                .select(
                    """
                    id,
                    user_id,
                    title,
                    description,
                    image_url,
                    created_at,
                    users:users!recipes_user_id_fkey (
                        id,
                        name,
                        avatar_url
                    )
                    """
                )
                .order("created_at", ascending: false)
                .execute()
                .value
            recipes = data
            await loadLikedRecipes()
        } catch {
            errorMessage = error.localizedDescription
            recipes = []
        }
        isLoading = false
    }

    private func loadLikedRecipes() async {
        do {
            let likes: [Like] = try await client
                .from("likes")
                .select("user_id,recipe_id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            likedRecipeIds = Set(likes.map { $0.recipe_id })
        } catch {
            // Non-blocking: surface error but keep recipes
            errorMessage = error.localizedDescription
        }
    }

    func toggleLike(for recipeId: Int) async {
        if likedRecipeIds.contains(recipeId) {
            await unlike(recipeId: recipeId)
        } else {
            await like(recipeId: recipeId)
        }
    }

    func isLiked(_ recipeId: Int) -> Bool {
        likedRecipeIds.contains(recipeId)
    }

    private func like(recipeId: Int) async {
        guard !likeInProgress.contains(recipeId) else { return }
        likeInProgress.insert(recipeId)
        defer { likeInProgress.remove(recipeId) }
        do {
            let payload = LikeInsert(recipe_id: recipeId, user_id: userId)
            try await client
                .from("likes")
                .insert(payload)
                .execute()
            likedRecipeIds.insert(recipeId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func unlike(recipeId: Int) async {
        guard !likeInProgress.contains(recipeId) else { return }
        likeInProgress.insert(recipeId)
        defer { likeInProgress.remove(recipeId) }
        do {
            try await client
                .from("likes")
                .delete()
                .eq("recipe_id", value: recipeId)
                .eq("user_id", value: userId.uuidString)
                .execute()
            likedRecipeIds.remove(recipeId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
