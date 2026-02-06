//
//  Tag.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation

struct Tag: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var name: String
    var color: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case color
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        color: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.color = color
        self.createdAt = createdAt
    }
}
