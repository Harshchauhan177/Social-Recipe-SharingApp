import Foundation

struct LikeInsert: Encodable {
    let recipe_id: Int
    let user_id: UUID
}
