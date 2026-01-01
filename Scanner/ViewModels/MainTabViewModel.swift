//
//  MainTabViewModel.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class MainTabViewModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var showingScanner = false
    @Published var scannedPages: [UIImage] = []
    @Published var showingNamingDialog = false
    @Published var documentName = ""
    
    func handleScannedPages(_ images: [UIImage]) {
        scannedPages = images
        documentName = generateDefaultDocumentName()
        showingNamingDialog = true
    }
    
    func generateDefaultDocumentName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Document \(formatter.string(from: Date()))"
    }
    
    func saveDocument(name: String, images: [UIImage]) {
        // TODO: Save document to database
        // For now, just print
        print("Saving document '\(name)' with \(images.count) pages")
        
        // Clear state after saving
        scannedPages = []
        documentName = ""
        showingNamingDialog = false
        
        // Switch to Files tab
        selectedTab = 1
    }
    
    func cancelDocumentNaming() {
        scannedPages = []
        documentName = ""
        showingNamingDialog = false
    }
    
    func openScanner() {
        showingScanner = true
    }
    
    func handleTabSelection(_ newTab: Int) {
        selectedTab = newTab
        // Auto-open scanner when Scan tab is selected
        if newTab == 2 {
            showingScanner = true
        }
    }
}
