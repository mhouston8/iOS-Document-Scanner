//
//  SupabaseDatabaseClient.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import UIKit
import Supabase

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
        // 1. Upload images to Supabase Storage
        var pageUrls: [String] = []
        
        for (index, image) in pages.enumerated() {
            let uid = try await client.auth.session.user.id.uuidString.lowercased()
            let path = "\(uid)/\(document.id)/page_\(index + 1).jpg"
            
            // Convert UIImage to Data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "SupabaseDatabaseClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])
            }
            
            
            // Upload to Storage
            do {
                try await client.storage
                    .from(SupabaseConfig.documentsBucket)
                    .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))
                print("DEBUG: Successfully uploaded page \(index + 1)")
            } catch {
                print("DEBUG: Upload failed for page \(index + 1): \(error)")
                throw error
            }
            
            // Get public URL
            let url = try client.storage
                .from(SupabaseConfig.documentsBucket)
                .getPublicURL(path: path)
            
            pageUrls.append(url.absoluteString)
        }
        
        // 2. Create Document record in database
        try await client.database
            .from("Document")
            .insert(document)
            .execute()
        
        // 3. Create DocumentPage records for each page
        // Note: user_id is automatically set to auth.uid() via database DEFAULT
        for (index, imageUrl) in pageUrls.enumerated() {
            let page = DocumentPage(
                documentId: document.id,
                userId: document.userId, // Placeholder - database DEFAULT will override
                pageNumber: index + 1,
                imageUrl: imageUrl
            )
            
            try await client.database
                .from("DocumentPage")
                .insert(page)
                .execute()
        }
        
        print("Successfully saved document: \(document.name) with \(pages.count) pages")
    }
    
    func fetchDocuments(userId: UUID) async throws -> [Document] {
        // TODO: Implement Supabase query
        // Fetch all documents for user
        
        return []
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
