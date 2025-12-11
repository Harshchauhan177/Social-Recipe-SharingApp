import SwiftUI
import Supabase

struct RecipeFormView: View {
    let userId: UUID
    var onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = RecipeFormViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g. Creamy Tomato Pasta", text: $vm.title)
                        .textInputAutocapitalization(.words)
                }

                Section("Description") {
                    TextEditor(text: $vm.description)
                        .frame(minHeight: 140)
                }

                Section("Image URL (optional)") {
                    TextField("https://...", text: $vm.imageURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }

                if let error = vm.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("New Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(vm.isLoading ? "Posting..." : "Post") {
                        Task { await submit() }
                    }
                    .disabled(!vm.canSubmit || vm.isLoading)
                }
            }
        }
    }

    private func submit() async {
        let success = await vm.submit(userId: userId)
        if success {
            vm.reset()
            onComplete()
            dismiss()
        }
    }
}
