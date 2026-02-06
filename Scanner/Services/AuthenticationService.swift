//
//  AuthenticationService.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import Supabase
import Combine

@MainActor
class AuthenticationService: ObservableObject {
    private let client: SupabaseClient
    
    // Published properties for UI reactivity
    @Published var isAnonymous: Bool = true
    @Published var userEmail: String? = nil
    @Published var isSignedIn: Bool = false
    
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
    
    /// Updates published auth state properties from current session
    func refreshAuthState() async {
        do {
            let session = try await client.auth.session
            isSignedIn = true
            userEmail = session.user.email
            isAnonymous = session.user.isAnonymous ?? (session.user.email == nil)
        } catch {
            isSignedIn = false
            userEmail = nil
            isAnonymous = true
        }
    }
    
    // MARK: - Sign Up (New Account)
    
    /// Creates a new account with email and password (for users who aren't anonymous)
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
        await refreshAuthState()
        print("Signed up user: \(email)")
    }
    
    // MARK: - Sign In
    
    /// Signs in with email and password
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
        await refreshAuthState()
        print("Signed in user: \(email)")
    }
    
    // MARK: - Anonymous Sign In
    
    /// Signs in anonymously - creates a temporary user session
    func signInAnonymously() async throws {
        try await client.auth.signInAnonymously()
        await refreshAuthState()
        print("Signed in anonymously")
    }
    
    // MARK: - Link Anonymous Account to Email
    
    /// Upgrades an anonymous account to a permanent account with email/password
    /// This preserves the user's UUID so all their data remains linked
    func linkEmail(email: String, password: String) async throws {
        // Update the current anonymous user with email and password
        try await client.auth.update(user: UserAttributes(
            email: email,
            password: password
        ))
        await refreshAuthState()
        print("Linked email to anonymous account: \(email)")
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        try await client.auth.signOut()
        await refreshAuthState()
        print("Signed out user")
    }
    
    // MARK: - Password Reset
    
    /// Sends a password reset email
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
        print("Password reset email sent to: \(email)")
    }
    
    // MARK: - Session Management
    
    func getCurrentSession() async throws -> UUID? {
        let session = try await client.auth.session
        return UUID(uuidString: session.user.id.uuidString)
    }
    
    func refreshSession() async throws {
        try await client.auth.refreshSession()
        await refreshAuthState()
        print("Refreshed session")
    }
}
