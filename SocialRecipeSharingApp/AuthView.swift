import SwiftUI

struct AuthView: View {
    @StateObject private var vm: AuthViewModel

    init(vm: AuthViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Mini Recipes")
                .font(.largeTitle).bold()

            TextField("Email", text: $vm.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $vm.password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)

            if let err = vm.errorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button(action: { Task { await vm.signIn() } }) {
                Text(vm.isLoading ? "Signing in..." : "Sign In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isLoading || !vm.canSubmit)

            Button(action: { Task { await vm.signUp() } }) {
                Text(vm.isLoading ? "Signing up..." : "Create Account")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(vm.isLoading || !vm.canSubmit)
        }
        .padding()
    }
}
