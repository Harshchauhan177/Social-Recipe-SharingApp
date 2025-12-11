import Combine
import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var session: Session?

    private let client = SupabaseManager.shared.client

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init() {
        Task { await loadSession() }
    }

    func signUp() async {
        guard validateInputs() else { return }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await self.client.auth.signUp(email: self.email, password: self.password)
            self.session = response.session
            if self.session == nil {
                errorMessage = "Check your email to confirm, then sign in."
            }
            if let session = self.session {
                await ensureUserProfile(session: session)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signIn() async {
        guard validateInputs() else { return }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await self.client.auth.signIn(email: self.email, password: self.password)
            self.session = response
            if let session = self.session {
                await ensureUserProfile(session: session)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        isLoading = true
        errorMessage = nil
        do {
            try await self.client.auth.signOut()
        } catch {
            // If no session, ignore
        }
        session = nil
        isLoading = false
    }

    private func loadSession() async {
        do {
            session = try await self.client.auth.session
            if let session = session {
                await ensureUserProfile(session: session)
            }
        } catch {
            session = nil
        }
    }

    private func ensureUserProfile(session: Session) async {
        do {
            try await self.client
                .from("users")
                .upsert([
                    "id": session.user.id.uuidString,
                    "name": session.user.email ?? ""
                ])
                .execute()
        } catch {
            print("Profile upsert failed: \(error.localizedDescription)")
        }
    }
    private func validateInputs() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            errorMessage = "Please enter email and password."
            return false
        }

        guard trimmedEmail.contains("@") else {
            errorMessage = "Enter a valid email."
            return false
        }

        guard trimmedPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return false
        }

        return true
    }
}
