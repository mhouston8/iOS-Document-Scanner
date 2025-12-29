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
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}
