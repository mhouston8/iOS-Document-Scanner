//
//  DocumentsViewModel.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import SwiftUI
import Combine

struct DocumentWithThumbnail: Identifiable {
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
class DocumentsViewModel: ObservableObject {
    @Published var documents: [DocumentWithThumbnail] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let databaseService: DatabaseService
    private let authService: AuthenticationService
    
    init(
        databaseService: DatabaseService,
        authService: AuthenticationService
    ) {
        self.databaseService = databaseService
        self.authService = authService
    }
    
    func loadDocuments() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                guard let userId = await authService.currentUserId() else {
                    errorMessage = "No authenticated user"
                    isLoading = false
                    return
                }
                
                // Read all documents
                let fetchedDocuments = try await databaseService.readDocuments(userId: userId)
                
                // Read first page (thumbnail) for each document
                var documentsWithThumbnails: [DocumentWithThumbnail] = []
                
                for document in fetchedDocuments {
                    do {
                        let firstPage = try await databaseService.readDocumentThumbnail(documentId: document.id)
                        let docWithThumbnail = DocumentWithThumbnail(
                            document: document,
                            thumbnailUrl: firstPage?.thumbnailUrl
                        )
                        documentsWithThumbnails.append(docWithThumbnail)
                    } catch {
                        // If fetching thumbnail fails, still add document without thumbnail
                        print("WARNING [DocumentsViewModel]: Failed to fetch thumbnail for document \(document.id): \(error)")
                        let docWithThumbnail = DocumentWithThumbnail(
                            document: document,
                            thumbnailUrl: nil
                        )
                        documentsWithThumbnails.append(docWithThumbnail)
                    }
                }
                
                documents = documentsWithThumbnails
                print("Loaded \(documents.count) documents")
            } catch {
                errorMessage = "Failed to load documents: \(error.localizedDescription)"
                print("ERROR [DocumentsViewModel]: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
}
