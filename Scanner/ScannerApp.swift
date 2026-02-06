//
//  ScannerApp.swift
//  Axio Scan
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
                        // Check authentication state on app launch
                        if await authService.isAuthenticated() {
                            // Already authenticated - refresh state to update UI
                            await authService.refreshAuthState()
                        } else {
                            // Not authenticated - sign in anonymously
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
