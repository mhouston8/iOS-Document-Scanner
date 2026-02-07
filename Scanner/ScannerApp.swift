//
//  ScannerApp.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import RevenueCat

@main
struct ScannerApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var authService = AuthenticationService()
    @StateObject private var revenueCatService = RevenueCatService()
    
    init() {
        // Configure RevenueCat on app launch
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
        Purchases.logLevel = .debug // Remove or change to .error for production
    }
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(authService)
                    .environmentObject(revenueCatService)
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
                        
                        // Link RevenueCat to Supabase user ID
                        if let userId = await authService.currentUserId() {
                            await revenueCatService.connectUserToRevenueCat(userId: userId.uuidString)
                        }
                        
                        // Check subscription status
                        await revenueCatService.checkSubscriptionStatus()
                    }
            } else {
                OnboardingView()
            }
        }
    }
}
