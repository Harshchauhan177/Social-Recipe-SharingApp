import SwiftUI
import Supabase

struct FeedView: View {
    let userId: UUID
    let userEmail: String
    @StateObject private var vm: FeedViewModel
    @State private var showComposer = false

    init(userId: UUID, userEmail: String) {
        self.userId = userId
        self.userEmail = userEmail
        _vm = StateObject(wrappedValue: FeedViewModel(userId: userId))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: []) {
                ForEach(vm.recipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        cardView(for: recipe)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .overlay {
            if vm.isLoading {
                ProgressView()
            } else if vm.recipes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife.circle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No recipes yet")
                        .font(.headline)
                    Text("Tap the + button to share your first recipe.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .task {
            await vm.load()
        }
        .refreshable {
            await vm.load()
        }
        .navigationTitle("Recipes")
        .alert(
            "Error",
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) { vm.errorMessage = nil }
            },
            message: {
                Text(vm.errorMessage ?? "")
            }
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showComposer = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showComposer) {
            RecipeFormView(userId: userId) {
                showComposer = false
                Task { await vm.load() }
            }
        }
    }

    @ViewBuilder
    private func cardView(for recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image banner
            if let urlString = recipe.image_url, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.08))
                                .frame(height: 200)
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(16)
                            .overlay(alignment: .topTrailing) {
                                if let name = recipe.users?.name, !name.isEmpty {
                                    Text(name)
                                        .font(.caption2)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.thinMaterial)
                                        .clipShape(Capsule())
                                        .padding(8)
                                }
                            }
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }

            HStack(alignment: .top, spacing: 12) {
                avatarView(for: recipe)
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(authorName(for: recipe))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(formattedDate(for: recipe))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if let desc = recipe.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            HStack {
                Button {
                    Task { await vm.toggleLike(for: recipe.id) }
                } label: {
                    Label(
                        "\(recipe.likeCount)",
                        systemImage: vm.isLiked(recipe.id) ? "heart.fill" : "heart"
                    )
                    .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .tint(vm.isLiked(recipe.id) ? .pink : .blue)
                .disabled(vm.likeInProgress.contains(recipe.id))

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
        )
    }

    private func formattedDate(for recipe: Recipe) -> String {
        if let date = recipe.createdDate {
            return date.formatted(.dateTime.month().day().hour().minute())
        }
        return recipe.created_at
    }

    private func authorName(for recipe: Recipe) -> String {
        if let name = recipe.users?.name, !name.isEmpty {
            return name
        }
        if let authorId = recipe.users?.id {
            return "Posted by \(String(authorId.uuidString.prefix(6)))"
        }
        return "Posted by \(String(recipe.user_id.uuidString.prefix(6)))"
    }

    @ViewBuilder
    private func avatarView(for recipe: Recipe) -> some View {
        let initials = recipe.users?.name?
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
        let text = initials?.map { String($0) }.joined().uppercased()

        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 42, height: 42)
            .overlay(
                Text(text ?? "👨‍🍳")
                    .font(.subheadline)
            )
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.08))
            .frame(height: 200)
            .overlay(
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundColor(.secondary)
            )
    }
}
