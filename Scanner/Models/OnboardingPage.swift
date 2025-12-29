//
//  OnboardingPage.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "doc.text.viewfinder",
            title: "Scan Documents",
            description: "Capture documents instantly with automatic edge detection and multi-page scanning",
            color: AppColors.scanBlue
        ),
        OnboardingPage(
            icon: "wand.and.stars",
            title: "Edit & Enhance",
            description: "Crop, rotate, and adjust brightness and contrast to perfect your scans",
            color: AppColors.editPurple
        ),
        OnboardingPage(
            icon: "square.and.arrow.up",
            title: "Export & Share",
            description: "Save as PDF or images and share anywhere with the iOS share sheet",
            color: AppColors.exportGreen
        ),
        OnboardingPage(
            icon: "square.stack.3d.up",
            title: "Merge Documents",
            description: "Combine multiple scans into a single PDF document effortlessly",
            color: AppColors.mergeOrange
        ),
        OnboardingPage(
            icon: "signature",
            title: "Watermark & Sign",
            description: "Add watermarks and digital signatures to protect and authenticate your documents",
            color: AppColors.watermarkPink
        )
    ]
}
