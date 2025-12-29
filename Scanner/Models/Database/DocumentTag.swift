//
//  DocumentTag.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation

struct DocumentTag: Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    let tagId: UUID
    
    enum CodingKeys: String, CodingKey {
        case id
        case documentId = "document_id"
        case tagId = "tag_id"
    }
    
    init(
        id: UUID = UUID(),
        documentId: UUID,
        tagId: UUID
    ) {
        self.id = id
        self.documentId = documentId
        self.tagId = tagId
    }
}
