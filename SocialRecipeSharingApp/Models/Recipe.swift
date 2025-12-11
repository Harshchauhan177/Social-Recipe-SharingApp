import Foundation

struct Recipe: Identifiable, Decodable {
    let id: Int
    let user_id: UUID
    let title: String
    let description: String?
    let image_url: String?
    let created_at: String
    let users: RecipeUser?
    let likes: [LikeCountResult]?

    var createdDate: Date? {
        ISO8601DateFormatter().date(from: created_at)
    }

    var likeCount: Int {
        likes?.first?.count ?? 0
    }
}

struct RecipeUser: Decodable {
    let id: UUID?
    let name: String?
    let avatar_url: String?
}

struct LikeCountResult: Decodable {
    let count: Int?
}
