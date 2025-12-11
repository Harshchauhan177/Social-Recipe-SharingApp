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
                    TabView {
                        FeedView(userId: session.user.id, userEmail: session.user.email ?? "user")
                            .tabItem {
                                Label("Feed", systemImage: "house.fill")
                            }

                        AddRecipeView(session: session)
                            .tabItem {
                                Label("Add", systemImage: "plus.circle")
                            }

                        ProfileView(session: session) {
                            Task { await vm.signOut() }
                        }
                            .tabItem {
                                Label("Profile", systemImage: "person.crop.circle")
                            }
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
