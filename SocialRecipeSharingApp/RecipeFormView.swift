import SwiftUI
import Supabase
import PhotosUI

struct RecipeFormView: View {
    let userId: UUID
    var onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = RecipeFormViewModel()
    @State private var photoItem: PhotosPickerItem?

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

                Section("Image") {
                    PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                        HStack {
                            Image(systemName: "photo")
                            Text(vm.pickedImagePreview == nil ? "Choose photo" : "Change photo")
                        }
                    }
                    if let preview = vm.pickedImagePreview {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipped()
                            .cornerRadius(12)
                    }
                    TextField("or paste an image URL", text: $vm.imageURL)
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
            .onChange(of: photoItem) { _ in
                loadPhoto()
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

    private func loadPhoto() {
        guard let photoItem else { return }
        Task {
            if let data = try? await photoItem.loadTransferable(type: Data.self) {
                await MainActor.run {
                    vm.pickedImageData = data
                    vm.pickedImagePreview = UIImage(data: data)
                }
            }
        }
    }
}
