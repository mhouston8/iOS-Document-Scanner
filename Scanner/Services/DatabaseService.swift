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
    
    func fetchDocuments(userId: UUID) async throws -> [Document] {
        try await client.fetchDocuments(userId: userId)
    }
    
    func fetchDocument(id: UUID) async throws -> Document? {
        try await client.fetchDocument(id: id)
    }
    
    func updateDocument(_ document: Document) async throws {
        try await client.updateDocument(document)
    }
    
    func deleteDocument(_ document: Document) async throws {
        try await client.deleteDocument(document)
    }
    
    // MARK: - Document Page Operations
    
    func fetchDocumentPages(documentId: UUID) async throws -> [DocumentPage] {
        try await client.fetchDocumentPages(documentId: documentId)
    }
    
    func addPageToDocument(_ page: DocumentPage, image: UIImage) async throws {
        try await client.addPageToDocument(page, image: image)
    }
    
    func deletePage(_ page: DocumentPage) async throws {
        try await client.deletePage(page)
    }
    
    // MARK: - Storage Operations
    
    func uploadImage(_ image: UIImage, to bucket: String, path: String) async throws -> String {
        try await client.uploadImage(image, to: bucket, path: path)
    }
    
    func deleteImage(from bucket: String, path: String) async throws {
        try await client.deleteImage(from: bucket, path: path)
    }
    
    // MARK: - Folder Operations
    
    func fetchFolders(userId: UUID) async throws -> [Folder] {
        try await client.fetchFolders(userId: userId)
    }
    
    func createFolder(_ folder: Folder) async throws {
        try await client.createFolder(folder)
    }
    
    func updateFolder(_ folder: Folder) async throws {
        try await client.updateFolder(folder)
    }
    
    func deleteFolder(_ folder: Folder) async throws {
        try await client.deleteFolder(folder)
    }
    
    // MARK: - Tag Operations
    
    func fetchTags(userId: UUID) async throws -> [Tag] {
        try await client.fetchTags(userId: userId)
    }
    
    func createTag(_ tag: Tag) async throws {
        try await client.createTag(tag)
    }
    
    func updateTag(_ tag: Tag) async throws {
        try await client.updateTag(tag)
    }
    
    func deleteTag(_ tag: Tag) async throws {
        try await client.deleteTag(tag)
    }
    
    func addTagToDocument(documentId: UUID, tagId: UUID) async throws {
        try await client.addTagToDocument(documentId: documentId, tagId: tagId)
    }
    
    func removeTagFromDocument(documentId: UUID, tagId: UUID) async throws {
        try await client.removeTagFromDocument(documentId: documentId, tagId: tagId)
    }
}
