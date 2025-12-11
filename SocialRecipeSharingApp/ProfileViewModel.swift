import Combine
import Foundation
import Supabase

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var myRecipes: [Recipe] = []
    @Published var likedRecipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.shared.client
    private let userId: UUID

    init(userId: UUID) {
        self.userId = userId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        async let mineTask: Void = loadMyRecipes()
        async let likesTask: Void = loadLikedRecipes()
        _ = await (try? mineTask, try? likesTask)
        isLoading = false
    }

    private func loadMyRecipes() async {
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
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            myRecipes = data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadLikedRecipes() async {
        do {
            let rows: [LikedRecipeRow] = try await client
                .from("likes")
                .select(
                    """
                    recipe_id,
                    recipes:recipe_id (
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
                    )
                    """
                )
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            likedRecipes = rows.compactMap { $0.recipes }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
