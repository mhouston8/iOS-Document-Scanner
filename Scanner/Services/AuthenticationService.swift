//
//  AuthenticationService.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import Supabase
import Combine

class AuthenticationService: ObservableObject {
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.publishableKey
        )
    }
    
    // MARK: - Authentication State
    
    func currentUserId() async -> UUID? {
        do {
            let session = try await client.auth.session
            return UUID(uuidString: session.user.id.uuidString)
        } catch {
            return nil
        }
    }
    
    func isAuthenticated() async -> Bool {
        return await currentUserId() != nil
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String) async throws {
        // TODO: Implement Supabase Auth sign up
        // await auth.signUp(email: email, password: password)
        
        print("Signing up user: \(email)")
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        // TODO: Implement Supabase Auth sign in
        // await auth.signIn(email: email, password: password)
        
        print("Signing in user: \(email)")
    }
    
    // MARK: - Anonymous Sign In
    
    func signInAnonymously() async throws {
        // Sign in anonymously - creates a temporary user session
        // This allows testing with RLS enabled
        try await client.auth.signInAnonymously()
        print("Signed in anonymously")
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        try await client.auth.signOut()
        print("Signed out user")
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        // TODO: Implement Supabase Auth password reset
        // await auth.resetPassword(email: email)
        
        print("Resetting password for: \(email)")
    }
    
    // MARK: - Session Management
    
    func getCurrentSession() async throws -> UUID? {
        // Get current session and return user ID
        let session = try await client.auth.session
        return UUID(uuidString: session.user.id.uuidString)
    }
    
    func refreshSession() async throws {
        // Refresh authentication session
        try await client.auth.refreshSession()
        print("Refreshed session")
    }
}
