//
//  AppColors.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct AppColors {
    // MARK: - Background Colors (adapt to light/dark)
    
    static let backgroundPrimary = Color(UIColor.systemBackground)
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
    
    // Gradient backgrounds for onboarding (adapt to light/dark)
    static var backgroundGradientStart: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1)
                : UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1)
        })
    }
    
    static var backgroundGradientEnd: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1)
                : UIColor(red: 0.9, green: 0.9, blue: 0.98, alpha: 1)
        })
    }
    
    // MARK: - Text Colors (adapt to light/dark)
    
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)
    
    // MARK: - Page Indicator Colors
    
    static var pageIndicatorActive: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor.darkGray
        })
    }
    
    static var pageIndicatorInactive: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.3)
                : UIColor.lightGray.withAlphaComponent(0.5)
        })
    }
    
    // MARK: - Button Colors
    
    static var buttonSecondaryBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.2)
                : UIColor.black.withAlphaComponent(0.1)
        })
    }
    
    // MARK: - Feature Colors (consistent across light/dark)
    
    static let scanBlue = Color.blue
    static let editPurple = Color.purple
    static let exportGreen = Color.green
    static let mergeOrange = Color.orange
    static let watermarkPink = Color.pink
    
    // MARK: - System Colors (convenience)
    
    static let separator = Color(UIColor.separator)
    static let groupedBackground = Color(UIColor.systemGroupedBackground)
}
