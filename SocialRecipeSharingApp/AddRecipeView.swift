import SwiftUI
import Supabase

struct AddRecipeView: View {
    let session: Session
    @State private var showComposer = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                    .padding(.top, 40)

                Text("Share a new recipe")
                    .font(.title2).bold()
                Text("Add a title, description, and photo to inspire others.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button {
                    showComposer = true
                } label: {
                    Text("Add Recipe")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationTitle("New Recipe")
        }
        .sheet(isPresented: $showComposer) {
            RecipeFormView(userId: session.user.id) {
                showComposer = false
            }
        }
    }
}
