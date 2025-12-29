//
//  Document.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation

struct Document: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var name: String
    let createdAt: Date
    var updatedAt: Date
    var folderId: UUID?
    var isFavorite: Bool
    var pageCount: Int
    var fileSize: Int64
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case folderId = "folder_id"
        case isFavorite = "is_favorite"
        case pageCount = "page_count"
        case fileSize = "file_size"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        folderId: UUID? = nil,
        isFavorite: Bool = false,
        pageCount: Int = 0,
        fileSize: Int64 = 0
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.folderId = folderId
        self.isFavorite = isFavorite
        self.pageCount = pageCount
        self.fileSize = fileSize
    }
}
