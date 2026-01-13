//
//  DatabaseClient.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import UIKit

protocol DatabaseClientProtocol {
    // MARK: - Document Operations
    
    func saveDocument(_ document: Document, pages: [UIImage]) async throws
    func fetchDocuments(userId: UUID) async throws -> [Document]
    func fetchDocument(id: UUID) async throws -> Document?
    func updateDocument(_ document: Document) async throws
    func deleteDocument(_ document: Document) async throws
    
    // MARK: - Document Page Operations
    
    func fetchDocumentPages(documentId: UUID) async throws -> [DocumentPage]
    func fetchFirstPage(documentId: UUID) async throws -> DocumentPage?
    func addPageToDocument(_ page: DocumentPage, image: UIImage) async throws
    func uploadDocumentPage(_ page: DocumentPage, image: UIImage) async throws -> String
    func updateDocumentPage(_ page: DocumentPage) async throws
    func updateDocumentPages(_ pages: [DocumentPage]) async throws
    func deletePage(_ page: DocumentPage) async throws
    
    // MARK: - Storage Operations
    
    func uploadImage(_ image: UIImage, to bucket: String, path: String) async throws -> String
    func deleteImage(from bucket: String, path: String) async throws
    
    // MARK: - Folder Operations
    
    func fetchFolders(userId: UUID) async throws -> [Folder]
    func createFolder(_ folder: Folder) async throws
    func updateFolder(_ folder: Folder) async throws
    func deleteFolder(_ folder: Folder) async throws
    
    // MARK: - Tag Operations
    
    func fetchTags(userId: UUID) async throws -> [Tag]
    func createTag(_ tag: Tag) async throws
    func updateTag(_ tag: Tag) async throws
    func deleteTag(_ tag: Tag) async throws
    func addTagToDocument(documentId: UUID, tagId: UUID) async throws
    func removeTagFromDocument(documentId: UUID, tagId: UUID) async throws
}
