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
    
    private let databaseService: DatabaseService
    private let authService: AuthenticationService
    
    init(
        databaseService: DatabaseService? = nil,
        authService: AuthenticationService
    ) {
        self.databaseService = databaseService ?? DatabaseService(client: SupabaseDatabaseClient())
        self.authService = authService
    }
    
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
        Task {
            do {
                // 1. Get current user ID
                guard let userId = await authService.currentUserId() else {
                    print("Error: No authenticated user")
                    // TODO: Show error alert to user
                    return
                }
                
                // 2. Calculate file size (sum of JPEG data sizes)
                let fileSize = images.reduce(Int64(0)) { total, image in
                    let imageDataSize = image.jpegData(compressionQuality: 0.8)?.count ?? 0
                    return total + Int64(imageDataSize)
                }
                
                // 3. Create Document model
                let document = Document(
                    userId: userId,
                    name: name,
                    pageCount: images.count,
                    fileSize: fileSize
                )
                
                // 4. Save document and pages to database
                try await databaseService.saveDocument(document, pages: images)
                
                print("Successfully saved document '\(name)' with \(images.count) pages")
                
                // 5. Clear state after successful save
                scannedPages = []
                documentName = ""
                showingNamingDialog = false
                selectedTab = 1 // Switch to Files tab
            } catch {
                print("Error saving document: \(error)")
                print("")
                // TODO: Show error alert to user
            }
        }
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
