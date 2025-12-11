import Foundation

struct Like: Decodable {
    let user_id: UUID
    let recipe_id: Int
}
