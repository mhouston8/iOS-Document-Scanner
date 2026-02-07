//
//  UserDevice.swift
//  Axio Scan
//
//  Created by Matthew Houston on 2/4/26.
//

import Foundation

struct UserDevice: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var fcmToken: String
    var platform: String
    var deviceName: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fcmToken = "fcm_token"
        case platform
        case deviceName = "device_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        fcmToken: String,
        platform: String = "ios",
        deviceName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.fcmToken = fcmToken
        self.platform = platform
        self.deviceName = deviceName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
