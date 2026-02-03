//
//  MergeManager.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import UIKit

enum MergeError: LocalizedError {
    case invalidDocuments
    case insufficientDocuments
    case failedToLoadPages(documentId: UUID)
    case failedToLoadImage(pageNumber: Int)
    case mergeFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidDocuments:
            return "Invalid documents provided"
        case .insufficientDocuments:
            return "At least 2 documents are required to merge"
        case .failedToLoadPages(let documentId):
            return "Failed to load pages for document \(documentId.uuidString)"
        case .failedToLoadImage(let pageNumber):
            return "Failed to load image for page \(pageNumber)"
        case .mergeFailed(let reason):
            return "Merge failed: \(reason)"
        }
    }
}

@MainActor
class MergeManager {
    private let databaseService: DatabaseService
    
    init(databaseService: DatabaseService) {
        self.databaseService = databaseService
    }
    
    /// Loads all pages from multiple documents and returns them as images with metadata
    func loadPagesFromDocuments(_ documents: [Document]) async throws -> [(document: Document, page: DocumentPage, image: UIImage)] {
        guard documents.count >= 2 else {
            throw MergeError.insufficientDocuments
        }
        
        var pagesWithImages: [(document: Document, page: DocumentPage, image: UIImage)] = []
        
        for document in documents {
            // Load pages for this document
            let pages = try await databaseService.readDocumentPagesFromDatabase(documentId: document.id)
            let sortedPages = pages.sorted { $0.pageNumber < $1.pageNumber }
            
            // Load images for each page
            for page in sortedPages {
                guard let imageUrl = DatabaseService.cacheBustedURL(from: page.imageUrl) else {
                    throw MergeError.failedToLoadImage(pageNumber: page.pageNumber)
                }
                
                var request = URLRequest(url: imageUrl)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let image = UIImage(data: data) else {
                    throw MergeError.failedToLoadImage(pageNumber: page.pageNumber)
                }
                
                pagesWithImages.append((document: document, page: page, image: image))
            }
        }
        
        return pagesWithImages
    }
    
    /// Creates a merged document from selected pages
    func createMergedDocument(
        userId: UUID,
        name: String,
        pages: [(document: Document, page: DocumentPage, image: UIImage)]
    ) async throws -> Document {
        guard !pages.isEmpty else {
            throw MergeError.mergeFailed("No pages provided")
        }
        
        // Calculate total file size
        let fileSize = pages.reduce(Int64(0)) { total, pageData in
            let imageDataSize = pageData.image.jpegData(compressionQuality: 0.8)?.count ?? 0
            return total + Int64(imageDataSize)
        }
        
        // Create document model
        let document = Document(
            userId: userId,
            name: name,
            pageCount: pages.count,
            fileSize: fileSize
        )
        
        // Extract images in order
        let images = pages.map { $0.image }
        
        // Save document and pages
        try await databaseService.createDocument(document, pages: images)
        
        return document
    }
}
