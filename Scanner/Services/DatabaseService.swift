//
//  DatabaseService.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import UIKit

class DatabaseService {
    
    // MARK: - Cache-Busting Helper
    
    /// Adds cache-busting query parameter to URL to ensure fresh image loads
    ///
    /// **How it works:**
    /// - When you update an image in Storage, the URL stays the same (e.g., `image.jpg`)
    /// - Browsers cache images by URL, so they show the old cached version
    /// - Adding a query parameter (e.g., `?t=1234567890`) makes the URL different
    /// - Browser treats it as a new URL and fetches fresh
    ///
    /// **Why it doesn't break:**
    /// - Servers ignore query parameters for static files
    /// - `image.jpg` and `image.jpg?t=123` both serve the same file
    /// - Only the browser's cache behavior changes
    ///
    /// **Example:**
    /// - Input:  `"https://example.com/image.jpg"`
    /// - Output: `"https://example.com/image.jpg?t=1735689600"` (timestamp changes each call)
    static func cacheBustedURL(from urlString: String) -> URL? {
        guard let url = URL(string: urlString) else { return nil }
        
        // Always update/replace the cache-busting parameter with current timestamp
        // This ensures the URL is unique each time, forcing fresh image loads
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        // Remove existing "t" parameter if present, then add new one with current timestamp
        var queryItems = components?.queryItems?.filter { $0.name != "t" } ?? []
        queryItems.append(URLQueryItem(name: "t", value: String(Int(Date().timeIntervalSince1970))))
        components?.queryItems = queryItems
        
        return components?.url ?? url
    }
    private let client: DatabaseClientProtocol
    
    init(client: DatabaseClientProtocol) {
        self.client = client
    }
    
    // MARK: - Document Operations
    
    func createDocument(_ document: Document, pages: [UIImage]) async throws {
        try await client.createDocument(document, pages: pages)
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
    
    func readDocumentThumbnail(documentId: UUID) async throws -> DocumentPage? {
        try await client.readDocumentThumbnail(documentId: documentId)
    }
    
    func updateDocumentPageInStorage(_ page: DocumentPage, image: UIImage) async throws -> (imageUrl: String, thumbnailUrl: String) {
        try await client.updateDocumentPageInStorage(page, image: image)
    }
    
    func updateDocumentPagesInDatabase(_ pages: [DocumentPage]) async throws {
        try await client.updateDocumentPagesInDatabase(pages)
    }
}
