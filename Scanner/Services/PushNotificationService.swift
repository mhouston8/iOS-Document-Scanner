//
//  PushNotificationService.swift
//  Axio Scan
//
//  Created by Matthew Houston on 2/4/26.
//

import Foundation
import UIKit
import Combine
import UserNotifications

@MainActor
class PushNotificationService: ObservableObject {
    
    @Published var fcmToken: String?
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    private var authService: AuthenticationService?
    private var databaseService: DatabaseService?
    private var tokenObserver: NSObjectProtocol?
    
    init() {
        setupTokenObserver()
    }
    
    /// Configure with dependencies for auto-saving tokens
    func configure(authService: AuthenticationService, databaseService: DatabaseService) {
        self.authService = authService
        self.databaseService = databaseService
        
        // If we already have a token, save it now
        if fcmToken != nil {
            Task {
                await saveTokenToDatabase()
            }
        }
    }
    
    private func setupTokenObserver() {
        // Listen for FCM token updates from AppDelegate
        tokenObserver = NotificationCenter.default.addObserver(
            forName: .fcmTokenReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let token = notification.userInfo?["token"] as? String else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.fcmToken = token
                // Auto-save if configured
                await self.saveTokenToDatabase()
            }
        }
    }
    
    deinit {
        if let observer = tokenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Request Permission
    
    /// Request push notification permissions from the user
    func requestPermission() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            
            if granted {
                // Register for remote notifications on main thread
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            await checkPermissionStatus()
            return granted
        } catch {
            print("Push notification permission error: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Check current permission status
    func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionStatus = settings.authorizationStatus
    }
    
    // MARK: - Token Management
    
    /// Save FCM token to database for the current user
    func saveTokenToDatabase() async {
        guard let token = fcmToken else {
            print("No FCM token available to save")
            return
        }
        
        guard let authService = authService,
              let databaseService = databaseService else {
            print("PushNotificationService not configured - call configure() first")
            return
        }
        
        guard let userId = await authService.currentUserId() else {
            print("No authenticated user to save FCM token for")
            return
        }
        
        let deviceName = await UIDevice.current.name
        
        let userDevice = UserDevice(
            userId: userId,
            fcmToken: token,
            platform: "ios",
            deviceName: deviceName
        )
        
        do {
            try await databaseService.upsertUserDevice(userDevice)
            print("FCM token saved to database")
        } catch {
            print("Failed to save FCM token: \(error.localizedDescription)")
        }
    }
    
    /// Remove FCM token from database (call on sign out)
    func removeTokenFromDatabase() async {
        guard let token = fcmToken else { return }
        
        guard let authService = authService,
              let databaseService = databaseService else {
            print("PushNotificationService not configured")
            return
        }
        
        guard let userId = await authService.currentUserId() else {
            print("No authenticated user to remove FCM token for")
            return
        }
        
        do {
            try await databaseService.deleteUserDevice(userId: userId, fcmToken: token)
            print("FCM token removed from database")
        } catch {
            print("Failed to remove FCM token: \(error.localizedDescription)")
        }
    }
}
