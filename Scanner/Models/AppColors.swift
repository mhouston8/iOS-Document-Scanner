//
//  AppColors.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct AppColors {
    // Background colors
    static let backgroundDarkStart = Color(red: 0.05, green: 0.05, blue: 0.1)
    static let backgroundDarkEnd = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.8)
    static let textTertiary = Color.white.opacity(0.7)
    
    // Page indicator colors
    static let pageIndicatorActive = Color.white
    static let pageIndicatorInactive = Color.white.opacity(0.3)
    
    // Button colors
    static let buttonSecondaryBackground = Color.white.opacity(0.2)
    
    // Feature colors (for onboarding and feature highlights)
    static let scanBlue = Color.blue
    static let editPurple = Color.purple
    static let exportGreen = Color.green
    static let mergeOrange = Color.orange
    static let watermarkPink = Color.pink
}
