//
//  User.swift
//  Axio Scan
//
//  Created by Matthew Houston on 2/4/26.
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var isPremiumSubscriber: Bool
    var lastSeenAt: Date?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case isPremiumSubscriber = "is_premium_subscriber"
        case lastSeenAt = "last_seen_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID,
        isPremiumSubscriber: Bool = false,
        lastSeenAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.isPremiumSubscriber = isPremiumSubscriber
        self.lastSeenAt = lastSeenAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
