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
    
    // MARK: - Document Operations
    
    func saveDocument(_ document: Document, pages: [UIImage]) async throws {
        // Track uploaded files for cleanup on error
        var uploadedPaths: [String] = []
        let uid = try await client.auth.session.user.id.uuidString.lowercased()
        
        do {
            // 1. Upload images to Supabase Storage
            var pageUrls: [String] = []
            
            for (index, image) in pages.enumerated() {
                let path = "\(uid)/\(document.id)/page_\(index + 1).jpg"
                
                // Convert UIImage to Data
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    let error = StorageError.conversionFailed("Failed to convert image \(index + 1) to JPEG data")
                    print("ERROR [saveDocument]: \(error.localizedDescription)")
                    throw error
                }
                
                // Upload to Storage
                do {
                    try await client.storage
                        .from(SupabaseConfig.documentsBucket)
                        .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))
                    uploadedPaths.append(path)
                    
                    // Get public URL
                    let url = try client.storage
                        .from(SupabaseConfig.documentsBucket)
                        .getPublicURL(path: path)
                    
                    pageUrls.append(url.absoluteString)
                } catch {
                    let error = StorageError.uploadFailed("Failed to upload page \(index + 1): \(error.localizedDescription)")
                    print("ERROR [saveDocument]: \(error.localizedDescription)")
                    print("ERROR [saveDocument]: Original error: \(error)")
                    throw error
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
                    imageUrl: imageUrl
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
                        try await client.storage
                            .from(SupabaseConfig.documentsBucket)
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
    
    func fetchDocuments(userId: UUID) async throws -> [Document] {
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
            let error = DatabaseError.fetchFailed("Failed to fetch documents: \(error.localizedDescription)")
            print("ERROR [fetchDocuments]: \(error.localizedDescription)")
            print("ERROR [fetchDocuments]: Original error: \(error)")
            throw error
        }
    }
    
    func fetchDocument(id: UUID) async throws -> Document? {
        // TODO: Implement Supabase query
        // Fetch single document by ID
        
        return nil
    }
    
    func updateDocument(_ document: Document) async throws {
        // TODO: Implement Supabase update
        // Update document metadata
        
        print("Updating document: \(document.id)")
    }
    
    func deleteDocument(_ document: Document) async throws {
        // TODO: Implement Supabase delete
        // 1. Delete DocumentPage records
        // 2. Delete files from Storage
        // 3. Delete Document record
        
        print("Deleting document: \(document.id)")
    }
    
    // MARK: - Document Page Operations
    
    func fetchDocumentPages(documentId: UUID) async throws -> [DocumentPage] {
        // TODO: Implement Supabase query
        // Fetch all pages for a document
        
        return []
    }
    
    func addPageToDocument(_ page: DocumentPage, image: UIImage) async throws {
        // TODO: Implement Supabase integration
        // 1. Upload image to Storage
        // 2. Create DocumentPage record
        //    Note: user_id is automatically set to auth.uid() via database DEFAULT
        
        print("Adding page to document: \(page.documentId)")
    }
    
    func deletePage(_ page: DocumentPage) async throws {
        // TODO: Implement Supabase delete
        // 1. Delete file from Storage
        // 2. Delete DocumentPage record
        
        print("Deleting page: \(page.id)")
    }
    
    // MARK: - Storage Operations
    
    func uploadImage(_ image: UIImage, to bucket: String, path: String) async throws -> String {
        // TODO: Implement Supabase Storage upload
        // Upload image and return URL
        
        return ""
    }
    
    func deleteImage(from bucket: String, path: String) async throws {
        // TODO: Implement Supabase Storage delete
        
    }
    
    // MARK: - Folder Operations
    
    func fetchFolders(userId: UUID) async throws -> [Folder] {
        // TODO: Implement Supabase query
        
        return []
    }
    
    func createFolder(_ folder: Folder) async throws {
        // TODO: Implement Supabase insert
        
    }
    
    func updateFolder(_ folder: Folder) async throws {
        // TODO: Implement Supabase update
        
    }
    
    func deleteFolder(_ folder: Folder) async throws {
        // TODO: Implement Supabase delete
        
    }
    
    // MARK: - Tag Operations
    
    func fetchTags(userId: UUID) async throws -> [Tag] {
        // TODO: Implement Supabase query
        
        return []
    }
    
    func createTag(_ tag: Tag) async throws {
        // TODO: Implement Supabase insert
        
    }
    
    func updateTag(_ tag: Tag) async throws {
        // TODO: Implement Supabase update
        
    }
    
    func deleteTag(_ tag: Tag) async throws {
        // TODO: Implement Supabase delete
        
    }
    
    func addTagToDocument(documentId: UUID, tagId: UUID) async throws {
        // TODO: Implement Supabase insert into DocumentTag junction table
        
    }
    
    func removeTagFromDocument(documentId: UUID, tagId: UUID) async throws {
        // TODO: Implement Supabase delete from DocumentTag junction table
        
    }
}
