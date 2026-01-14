//
//  SupabaseDatabaseClient.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import UIKit
import Supabase

// MARK: - Custom Errors

enum StorageError: LocalizedError {
    case conversionFailed(String)
    case uploadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .conversionFailed(let message):
            return "Image conversion failed: \(message)"
        case .uploadFailed(let message):
            return "Storage upload failed: \(message)"
        }
    }
}

enum DatabaseError: LocalizedError {
    case insertFailed(String)
    case fetchFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .insertFailed(let message):
            return "Database insert failed: \(message)"
        case .fetchFailed(let message):
            return "Database fetch failed: \(message)"
        case .updateFailed(let message):
            return "Database update failed: \(message)"
        case .deleteFailed(let message):
            return "Database delete failed: \(message)"
        }
    }
}

class SupabaseDatabaseClient: DatabaseClientProtocol {
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.publishableKey
        )
    }
    
    // MARK: - Helper Methods
    
    private func generateThumbnail(from image: UIImage, maxSize: CGFloat = 200) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var thumbnailSize: CGSize
        if aspectRatio > 1 {
            // Landscape
            thumbnailSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            // Portrait or square
            thumbnailSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnail ?? image
    }
    
    // MARK: - Document Operations
    
    func saveDocument(_ document: Document, pages: [UIImage]) async throws {
        // Track uploaded files for cleanup on error
        var uploadedPaths: [String] = []
        let uid = try await client.auth.session.user.id.uuidString.lowercased()
        
        do {
            // 1. Upload images and thumbnails to Supabase Storage
            var pageUrls: [String] = []
            var thumbnailUrls: [String?] = []
            
            for (index, image) in pages.enumerated() {
                let documentPath = "\(uid)/\(document.id)/page_\(index + 1).jpg"
                let thumbnailPath = "\(uid)/\(document.id)/thumbnail_\(index + 1).jpg"
                
                // Convert UIImage to Data for full-size image
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    let error = StorageError.conversionFailed("Failed to convert image \(index + 1) to JPEG data")
                    print("ERROR [saveDocument]: \(error.localizedDescription)")
                    throw error
                }
                
                // Generate thumbnail
                let thumbnail = generateThumbnail(from: image)
                guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) else {
                    let error = StorageError.conversionFailed("Failed to convert thumbnail \(index + 1) to JPEG data")
                    print("ERROR [saveDocument]: \(error.localizedDescription)")
                    throw error
                }
                
                // Upload full-size image to Storage
                do {
                    try await client.storage
                        .from(SupabaseConfig.documentsBucket)
                        .upload(documentPath, data: imageData, options: FileOptions(contentType: "image/jpeg"))
                    uploadedPaths.append(documentPath)
                    
                    // Get public URL for full-size image
                    let url = try client.storage
                        .from(SupabaseConfig.documentsBucket)
                        .getPublicURL(path: documentPath)
                    
                    pageUrls.append(url.absoluteString)
                } catch {
                    let error = StorageError.uploadFailed("Failed to upload page \(index + 1): \(error.localizedDescription)")
                    print("ERROR [saveDocument]: \(error.localizedDescription)")
                    print("ERROR [saveDocument]: Original error: \(error)")
                    throw error
                }
                
                // Upload thumbnail to Storage
                do {
                    try await client.storage
                        .from(SupabaseConfig.thumbnailsBucket)
                        .upload(thumbnailPath, data: thumbnailData, options: FileOptions(contentType: "image/jpeg"))
                    uploadedPaths.append(thumbnailPath)
                    
                    // Get public URL for thumbnail
                    let thumbnailUrl = try client.storage
                        .from(SupabaseConfig.thumbnailsBucket)
                        .getPublicURL(path: thumbnailPath)
                    
                    thumbnailUrls.append(thumbnailUrl.absoluteString)
                } catch {
                    print("WARNING [saveDocument]: Failed to upload thumbnail \(index + 1): \(error)")
                    // Don't fail the whole operation if thumbnail upload fails
                    thumbnailUrls.append(nil)
                }
            }
            
            // 2. Create Document record in database
            do {
                try await client.database
                    .from("Document")
                    .insert(document)
                    .execute()
            } catch {
                let error = DatabaseError.insertFailed("Failed to create document record: \(error.localizedDescription)")
                print("ERROR [saveDocument]: \(error.localizedDescription)")
                print("ERROR [saveDocument]: Original error: \(error)")
                throw error
            }
            
            // 3. Create DocumentPage records for each page
            // Note: user_id is automatically set to auth.uid() via database DEFAULT
            for (index, imageUrl) in pageUrls.enumerated() {
                let page = DocumentPage(
                    documentId: document.id,
                    userId: document.userId, // Placeholder - database DEFAULT will override
                    pageNumber: index + 1,
                    imageUrl: imageUrl,
                    thumbnailUrl: index < thumbnailUrls.count ? thumbnailUrls[index] : nil
                )
                
                do {
                    try await client.database
                        .from("DocumentPage")
                        .insert(page)
                        .execute()
                } catch {
                    let error = DatabaseError.insertFailed("Failed to create page \(index + 1) record: \(error.localizedDescription)")
                    print("ERROR [saveDocument]: \(error.localizedDescription)")
                    print("ERROR [saveDocument]: Original error: \(error)")
                    throw error
                }
            }
            
            print("Successfully saved document: \(document.name) with \(pages.count) pages")
            
        } catch {
            print("ERROR [saveDocument]: Failed to save document '\(document.name)'")
            print("ERROR [saveDocument]: Error type: \(type(of: error))")
            print("ERROR [saveDocument]: Error description: \(error.localizedDescription)")
            if let storageError = error as? StorageError {
                print("ERROR [saveDocument]: Storage error: \(storageError.localizedDescription)")
            } else if let databaseError = error as? DatabaseError {
                print("ERROR [saveDocument]: Database error: \(databaseError.localizedDescription)")
            } else {
                print("ERROR [saveDocument]: Unexpected error: \(error)")
            }
            
            // Cleanup: Delete uploaded files if database operations failed
            if !uploadedPaths.isEmpty {
                print("ERROR [saveDocument]: Cleaning up \(uploadedPaths.count) uploaded file(s)...")
                for path in uploadedPaths {
                    do {
                        // Determine which bucket based on path
                        let bucket = path.contains("thumbnail") ? SupabaseConfig.thumbnailsBucket : SupabaseConfig.documentsBucket
                        try await client.storage
                            .from(bucket)
                            .remove(paths: [path])
                        print("ERROR [saveDocument]: Cleaned up file: \(path)")
                    } catch {
                        print("ERROR [saveDocument]: Warning - Failed to cleanup file \(path): \(error)")
                    }
                }
            }
            
            // Re-throw the original error
            throw error
        }
    }
    
    func readDocuments(userId: UUID) async throws -> [Document] {
        do {
            let response: [Document] = try await client.database
                .from("Document")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("Fetched \(response.count) documents for user \(userId)")
            return response
        } catch {
            let error = DatabaseError.fetchFailed("Failed to read documents: \(error.localizedDescription)")
            print("ERROR [readDocuments]: \(error.localizedDescription)")
            print("ERROR [readDocuments]: Original error: \(error)")
            throw error
        }
    }
    
    func updateDocumentInDatabase(_ document: Document) async throws {
        // TODO: Implement Supabase update
        // Update document metadata
        
        print("Updating document: \(document.id)")
    }
    
    // MARK: - Document Page Operations
    
    func readDocumentPagesFromDatabase(documentId: UUID) async throws -> [DocumentPage] {
        do {
            let response: [DocumentPage] = try await client.database
                .from("DocumentPage")
                .select()
                .eq("document_id", value: documentId.uuidString)
                .order("page_number", ascending: true)
                .execute()
                .value
            
            print("Fetched \(response.count) pages for document \(documentId)")
            return response
        } catch {
            let error = DatabaseError.fetchFailed("Failed to read document pages: \(error.localizedDescription)")
            print("ERROR [readDocumentPagesFromDatabase]: \(error.localizedDescription)")
            print("ERROR [readDocumentPagesFromDatabase]: Original error: \(error)")
            throw error
        }
    }
    
    func readDocumentThumbnail(documentId: UUID) async throws -> DocumentPage? {
        do {
            let response: [DocumentPage] = try await client.database
                .from("DocumentPage")
                .select()
                .eq("document_id", value: documentId.uuidString)
                .eq("page_number", value: 1)
                .limit(1)
                .execute()
                .value
            
            return response.first
        } catch {
            let error = DatabaseError.fetchFailed("Failed to read document thumbnail: \(error.localizedDescription)")
            print("ERROR [readDocumentThumbnail]: \(error.localizedDescription)")
            print("ERROR [readDocumentThumbnail]: Original error: \(error)")
            throw error
        }
    }
    
    func uploadDocumentPageToStorage(_ page: DocumentPage, image: UIImage) async throws -> (imageUrl: String, thumbnailUrl: String) {
        let uid = try await client.auth.session.user.id.uuidString.lowercased()
        let documentPath = "\(uid)/\(page.documentId.uuidString)/page_\(page.pageNumber).jpg"
        let thumbnailPath = "\(uid)/\(page.documentId.uuidString)/thumbnail_\(page.pageNumber).jpg"
        
        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = StorageError.conversionFailed("Failed to convert image to JPEG data")
            print("ERROR [uploadDocumentPageToStorage]: \(error.localizedDescription)")
            throw error
        }
        
        // Generate thumbnail
        let thumbnail = generateThumbnail(from: image)
        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) else {
            let error = StorageError.conversionFailed("Failed to convert thumbnail to JPEG data")
            print("ERROR [uploadDocumentPageToStorage]: \(error.localizedDescription)")
            throw error
        }
        
        do {
            // Upload image to Storage (overwrites existing if path is the same)
            try await client.storage
                .from(SupabaseConfig.documentsBucket)
                .upload(documentPath, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))
            
            // Get public URL for image
            let imageUrl = try client.storage
                .from(SupabaseConfig.documentsBucket)
                .getPublicURL(path: documentPath)
            
            print("Uploaded DocumentPage image: \(documentPath)")
            
            // Upload thumbnail to Storage
            var thumbnailUrl: String
            do {
                try await client.storage
                    .from(SupabaseConfig.thumbnailsBucket)
                    .upload(thumbnailPath, data: thumbnailData, options: FileOptions(contentType: "image/jpeg", upsert: true))
                
                // Get public URL for thumbnail
                let thumbnailUrlObj = try client.storage
                    .from(SupabaseConfig.thumbnailsBucket)
                    .getPublicURL(path: thumbnailPath)
                
                thumbnailUrl = thumbnailUrlObj.absoluteString
                print("Uploaded DocumentPage thumbnail: \(thumbnailPath)")
            } catch {
                print("WARNING [uploadDocumentPageToStorage]: Failed to upload thumbnail: \(error)")
                // Don't fail the whole operation if thumbnail upload fails
                // Return empty string or existing thumbnail URL
                thumbnailUrl = page.thumbnailUrl ?? ""
            }
            
            return (imageUrl: imageUrl.absoluteString, thumbnailUrl: thumbnailUrl)
        } catch {
            let error = StorageError.uploadFailed("Failed to upload DocumentPage image: \(error.localizedDescription)")
            print("ERROR [uploadDocumentPageToStorage]: \(error.localizedDescription)")
            print("ERROR [uploadDocumentPageToStorage]: Original error: \(error)")
            throw error
        }
    }
    
    func updateDocumentPagesInDatabase(_ pages: [DocumentPage]) async throws {
        do {
            // Update each page individually (Supabase doesn't have native batch update)
            // But we can do them in parallel for better performance
            try await withThrowingTaskGroup(of: Void.self) { group in
                for page in pages {
                    group.addTask {
                        try await self.client.database
                            .from("DocumentPage")
                            .update(page)
                            .eq("id", value: page.id.uuidString)
                            .execute()
                    }
                }
                
                // Wait for all updates to complete
                try await group.waitForAll()
            }
            
            print("Updated \(pages.count) DocumentPage(s)")
        } catch {
            let error = DatabaseError.updateFailed("Failed to update DocumentPages: \(error.localizedDescription)")
            print("ERROR [updateDocumentPages]: \(error.localizedDescription)")
            print("ERROR [updateDocumentPages]: Original error: \(error)")
            throw error
        }
    }
    
}
