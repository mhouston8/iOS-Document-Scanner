//
//  ScannerApp.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

@main
struct ScannerApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var authService = AuthenticationService()
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(authService)
                    .task {
                        // Sign in anonymously on app launch if not already authenticated
                        // This allows testing with RLS enabled
                        if !(await authService.isAuthenticated()) {
                            do {
                                try await authService.signInAnonymously()
                            } catch {
                                print("Failed to sign in anonymously: \(error)")
                            }
                        }
                    }
            } else {
                OnboardingView()
            }
        }
    }
}
