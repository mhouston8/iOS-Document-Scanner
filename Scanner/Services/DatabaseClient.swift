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
    func createDocument(_ document: Document, pages: [UIImage]) async throws
    func readDocuments(userId: UUID) async throws -> [Document]
    func updateDocumentInDatabase(_ document: Document) async throws
    
    // MARK: - Document Page Operations
    func readDocumentPagesFromDatabase(documentId: UUID) async throws -> [DocumentPage]
    func readDocumentThumbnail(documentId: UUID) async throws -> DocumentPage?
    func updateDocumentPageInStorage(_ page: DocumentPage, image: UIImage) async throws -> (imageUrl: String, thumbnailUrl: String)
    func updateDocumentPagesInDatabase(_ pages: [DocumentPage]) async throws
}
