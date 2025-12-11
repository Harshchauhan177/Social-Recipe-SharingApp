import Foundation

struct RecipeInsert: Encodable {
    let title: String
    let description: String?
    let image_url: String?
    let user_id: UUID
}
