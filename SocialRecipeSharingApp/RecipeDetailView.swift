import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                imageSection

                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.title).bold()
                    Text("\(authorLine) • \(formattedDate)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let desc = recipe.description, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.primary)
                    } else {
                        Text("No description provided.")
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 12)
            }
            .padding()
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var formattedDate: String {
        if let date = recipe.createdDate {
            return date.formatted(.dateTime.month().day().hour().minute())
        }
        return recipe.created_at
    }

    private var authorLine: String {
        if let name = recipe.users?.name, !name.isEmpty {
            return name
        }
        return "Author \(recipe.user_id.uuidString.prefix(8))"
    }

    @ViewBuilder
    private var imageSection: some View {
        if let urlString = recipe.image_url,
           let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    progressPlaceholder
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipped()
                        .cornerRadius(16)
                case .failure:
                    noImagePlaceholder
                @unknown default:
                    noImagePlaceholder
                }
            }
        } else {
            noImagePlaceholder
        }
    }

    private var progressPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.1))
            .frame(height: 240)
            .overlay(ProgressView())
    }

    private var noImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.1))
            .frame(height: 240)
            .overlay(
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No image provided")
                        .foregroundColor(.secondary)
                }
            )
    }
}
