//
//  SupabaseManager.swift
//  SocialRecipeSharingApp
//
//  Created by harsh chauhan on 11/12/25.
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://pfmcwkihcpmdhadxbdhp.supabase.co")!,
            supabaseKey: "sb_publishable_lqIH3YfyyBbocqcgQRm7UA_gzGK3Bro"
        )
    }
}
