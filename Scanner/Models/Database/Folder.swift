//
//  Folder.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation

struct Folder: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var name: String
    var parentId: UUID?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case parentId = "parent_id"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        parentId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.parentId = parentId
        self.createdAt = createdAt
    }
}
