//
//  HomeViewModel.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import SwiftUI
import Combine

struct RecentDocument: Identifiable {
    let id: UUID
    let document: Document
    let thumbnailUrl: String?
    
    init(document: Document, thumbnailUrl: String?) {
        self.id = document.id
        self.document = document
        self.thumbnailUrl = thumbnailUrl
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var recentDocuments: [RecentDocument] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var documentCount: Int = 0
    
    private let databaseService: DatabaseService
    private let authService: AuthenticationService
    
    init(
        databaseService: DatabaseService,
        authService: AuthenticationService
    ) {
        self.databaseService = databaseService
        self.authService = authService
    }
    
    func loadRecentDocuments(limit: Int = 5) {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                guard let userId = await authService.currentUserId() else {
                    errorMessage = "No authenticated user"
                    isLoading = false
                    return
                }
                
                // Fetch all documents (sorted by created_at DESC)
                let allDocuments = try await databaseService.fetchDocuments(userId: userId)
                documentCount = allDocuments.count
                
                // Get the most recent documents (up to limit)
                let recentDocs = Array(allDocuments.prefix(limit))
                
                // Fetch first page (thumbnail) for each document
                var recentDocumentsWithThumbnails: [RecentDocument] = []
                
                for document in recentDocs {
                    do {
                        let firstPage = try await databaseService.fetchFirstPage(documentId: document.id)
                        let recentDoc = RecentDocument(
                            document: document,
                            thumbnailUrl: firstPage?.thumbnailUrl
                        )
                        recentDocumentsWithThumbnails.append(recentDoc)
                    } catch {
                        // If fetching thumbnail fails, still add document without thumbnail
                        print("WARNING [HomeViewModel]: Failed to fetch thumbnail for document \(document.id): \(error)")
                        let recentDoc = RecentDocument(
                            document: document,
                            thumbnailUrl: nil
                        )
                        recentDocumentsWithThumbnails.append(recentDoc)
                    }
                }
                
                recentDocuments = recentDocumentsWithThumbnails
                print("Loaded \(recentDocuments.count) recent documents")
            } catch {
                errorMessage = "Failed to load recent documents: \(error.localizedDescription)"
                print("ERROR [HomeViewModel]: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
}
