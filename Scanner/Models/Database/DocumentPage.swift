//
//  DocumentPage.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation

struct DocumentPage: Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    let userId: UUID
    let pageNumber: Int
    var imageUrl: String
    var thumbnailUrl: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case documentId = "document_id"
        case userId = "user_id"
        case pageNumber = "page_number"
        case imageUrl = "image_url"
        case thumbnailUrl = "thumbnail_url"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        documentId: UUID,
        userId: UUID = UUID(),  // Will be set by database DEFAULT auth.uid() if not provided
        pageNumber: Int,
        imageUrl: String,
        thumbnailUrl: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.documentId = documentId
        self.userId = userId
        self.pageNumber = pageNumber
        self.imageUrl = imageUrl
        self.thumbnailUrl = thumbnailUrl
        self.createdAt = createdAt
    }
}
