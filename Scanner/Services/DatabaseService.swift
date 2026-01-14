//
//  DatabaseService.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import UIKit

class DatabaseService {
    private let client: DatabaseClientProtocol
    
    init(client: DatabaseClientProtocol) {
        self.client = client
    }
    
    // MARK: - Document Operations
    
    func saveDocument(_ document: Document, pages: [UIImage]) async throws {
        try await client.saveDocument(document, pages: pages)
    }
    
    func readDocuments(userId: UUID) async throws -> [Document] {
        try await client.readDocuments(userId: userId)
    }
    
    func updateDocumentInDatabase(_ document: Document) async throws {
        try await client.updateDocumentInDatabase(document)
    }
    
    // MARK: - Document Page Operations
    
    func readDocumentPagesFromDatabase(documentId: UUID) async throws -> [DocumentPage] {
        try await client.readDocumentPagesFromDatabase(documentId: documentId)
    }
    
    func readFirstPageFromDatabase(documentId: UUID) async throws -> DocumentPage? {
        try await client.readFirstPageFromDatabase(documentId: documentId)
    }
    
    func uploadDocumentPageToStorage(_ page: DocumentPage, image: UIImage) async throws -> String {
        try await client.uploadDocumentPageToStorage(page, image: image)
    }
    
    func updateDocumentPagesInDatabase(_ pages: [DocumentPage]) async throws {
        try await client.updateDocumentPagesInDatabase(pages)
    }
}
