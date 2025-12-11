//
//  ContentView.swift
//  SocialRecipeSharingApp
//
//  Created by harsh chauhan on 11/12/25.
//

import SwiftUI
import Supabase

struct ContentView: View {
    @StateObject private var vm = AuthViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let session = vm.session {
                    VStack(spacing: 12) {
                        HStack {
                            Text(session.user.email ?? "")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Sign Out") {
                                Task { await vm.signOut() }
                            }
                        }
                        .padding(.horizontal)

                        FeedView(userId: session.user.id, userEmail: session.user.email ?? "user")
                    }
                } else {
                    AuthView(vm: vm)
                }
            }
            .animation(.easeInOut, value: vm.session != nil)
        }
    }
}

#Preview {
    ContentView()
}
