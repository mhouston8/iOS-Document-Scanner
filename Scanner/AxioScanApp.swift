//
//  ScannerApp.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import RevenueCat

@main
struct AxioScanApp: App {
    // Firebase initialization via AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var authService = AuthenticationService()
    @StateObject private var revenueCatService = RevenueCatService()
    @StateObject private var pushNotificationService = PushNotificationService()
    
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
                    .environmentObject(pushNotificationService)
                    .task {
                        let databaseService = DatabaseService(client: SupabaseDatabaseClient())
                        
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
                        
                        // Create User row if needed (for new users)
                        if let userId = await authService.currentUserId() {
                            do {
                                try await databaseService.createUserIfNeeded(userId: userId)
                            } catch {
                                print("Failed to create user: \(error)")
                            }
                        }
                        
                        // Link RevenueCat to Supabase user ID
                        if let userId = await authService.currentUserId() {
                            await revenueCatService.connectUserToRevenueCat(userId: userId.uuidString)
                        }
                        
                        // Check subscription status and save to database
                        await revenueCatService.checkSubscriptionStatus()
                        if let userId = await authService.currentUserId() {
                            do {
                                try await databaseService.saveSubscriptionStatusToDatabase(userId: userId, isPremium: revenueCatService.isPremium)
                            } catch {
                                print("Failed to save subscription status: \(error)")
                            }
                        }
                        
                        // Configure and request push notifications
                        pushNotificationService.configure(authService: authService, databaseService: databaseService)
                        let _ = await pushNotificationService.requestPermission()
                    }
            } else {
                OnboardingView()
            }
        }
    }
}
