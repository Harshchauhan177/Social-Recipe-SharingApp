import SwiftUI
import Supabase

struct ProfileView: View {
    let session: Session
    let onSignOut: () -> Void
    @StateObject private var vm: ProfileViewModel

    init(session: Session, onSignOut: @escaping () -> Void) {
        self.session = session
        self.onSignOut = onSignOut
        _vm = StateObject(wrappedValue: ProfileViewModel(userId: session.user.id))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                section(title: "My Recipes", recipes: vm.myRecipes)
                section(title: "Liked", recipes: vm.likedRecipes)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Profile")
        .task { await vm.load() }
        .refreshable { await vm.load() }
        .overlay {
            if vm.isLoading {
                ProgressView()
            }
        }
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
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(initials(for: session.user.email))
                        .font(.title2)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(session.user.email ?? "Unknown")
                    .font(.headline)
                Text("Member since \(formattedDate(session.user.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(role: .destructive) {
                onSignOut()
            } label: {
                Text("Sign Out")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private func section(title: String, recipes: [Recipe]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if vm.isLoading {
                    ProgressView()
                }
            }
            if recipes.isEmpty {
                Text("No items yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(recipes.prefix(5)) { recipe in
                        HStack(spacing: 12) {
                            thumbnail(for: recipe)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text(recipe.description ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                }
            }
        }
    }

    private func initials(for email: String?) -> String {
        guard let email = email, let first = email.first else { return "U" }
        return String(first).uppercased()
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "N/A" }
        return date.formatted(.dateTime.month().year())
    }

    @ViewBuilder
    private func thumbnail(for recipe: Recipe) -> some View {
        if let urlString = recipe.image_url, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 72, height: 72)
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipped()
                        .cornerRadius(10)
                case .failure:
                    placeholderThumb
                @unknown default:
                    placeholderThumb
                }
            }
        } else {
            placeholderThumb
        }
    }

    private var placeholderThumb: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.1))
            .frame(width: 72, height: 72)
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            )
    }
}
