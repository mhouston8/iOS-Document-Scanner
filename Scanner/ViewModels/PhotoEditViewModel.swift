//
//  PhotoEditViewModel.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import SwiftUI
import UIKit
import Combine

@MainActor
class PhotoEditViewModel: ObservableObject {
    @Published var pages: [DocumentPage] = []
    @Published var images: [UIImage] = []
    @Published var editedImages: [UIImage] = []
    @Published var currentPageIndex: Int = 0
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var hasUnsavedChanges = false
    
    let document: Document
    private let databaseService: DatabaseService
    
    init(document: Document, databaseService: DatabaseService) {
        self.document = document
        self.databaseService = databaseService
    }
    
    // MARK: - Loading
    
    func loadPages() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                // Fetch all pages for the document
                let fetchedPages = try await databaseService.fetchDocumentPages(documentId: document.id)
                pages = fetchedPages.sorted { $0.pageNumber < $1.pageNumber }
                
                // Load images from URLs
                var loadedImages: [UIImage] = []
                for page in pages {
                    if let imageUrl = URL(string: page.imageUrl) {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: imageUrl)
                            if let image = UIImage(data: data) {
                                loadedImages.append(image)
                            } else {
                                print("WARNING [PhotoEditViewModel]: Failed to create UIImage from data for page \(page.pageNumber)")
                                // Add placeholder or skip
                            }
                        } catch {
                            print("ERROR [PhotoEditViewModel]: Failed to load image for page \(page.pageNumber): \(error)")
                            // Continue loading other pages
                        }
                    }
                }
                
                images = loadedImages
                editedImages = loadedImages // Start with original images
                
                print("Loaded \(images.count) images for document \(document.id)")
            } catch {
                errorMessage = "Failed to load pages: \(error.localizedDescription)"
                print("ERROR [PhotoEditViewModel]: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Page Navigation
    
    var currentImage: UIImage? {
        guard currentPageIndex >= 0 && currentPageIndex < editedImages.count else {
            return nil
        }
        return editedImages[currentPageIndex]
    }
    
    var canGoToPreviousPage: Bool {
        currentPageIndex > 0
    }
    
    var canGoToNextPage: Bool {
        currentPageIndex < editedImages.count - 1
    }
    
    func goToPreviousPage() {
        guard canGoToPreviousPage else { return }
        currentPageIndex -= 1
    }
    
    func goToNextPage() {
        guard canGoToNextPage else { return }
        currentPageIndex += 1
    }
    
    // MARK: - Image Editing
    
    func updateCurrentImage(_ image: UIImage) {
        guard currentPageIndex >= 0 && currentPageIndex < editedImages.count else { return }
        editedImages[currentPageIndex] = image
        hasUnsavedChanges = true
    }
    
    func rotateCurrentImage(by degrees: CGFloat) {
        guard let currentImage = currentImage else { return }
        let rotated = rotateImage(currentImage, by: degrees)
        updateCurrentImage(rotated)
    }
    
    private func rotateImage(_ image: UIImage, by degrees: CGFloat) -> UIImage {
        let radians = degrees * .pi / 180
        let rotatedSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context.rotate(by: radians)
        context.scaleBy(x: 1.0, y: -1.0)
        
        context.draw(image.cgImage!, in: CGRect(
            x: -image.size.width / 2,
            y: -image.size.height / 2,
            width: image.size.width,
            height: image.size.height
        ))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    // MARK: - Saving
    
    func saveChanges() {
        Task {
            isSaving = true
            errorMessage = nil
            
            do {
                // Update each page's image
                for (index, image) in editedImages.enumerated() {
                    guard index < pages.count else { continue }
                    let page = pages[index]
                    
                    // Upload the edited image
                    let path = "documents/\(document.id.uuidString)/page_\(page.pageNumber).jpg"
                    let imageUrl = try await databaseService.uploadImage(image, to: "images", path: path)
                    
                    // Update the page record with new image URL
                    var updatedPage = page
                    updatedPage.imageUrl = imageUrl
                    // Note: We'd need an updatePage method in DatabaseService for this
                    // For now, we'll just upload the images
                }
                
                // Update document's updatedAt timestamp
                var updatedDocument = document
                updatedDocument.updatedAt = Date()
                try await databaseService.updateDocument(updatedDocument)
                
                hasUnsavedChanges = false
                print("Successfully saved changes for document \(document.id)")
            } catch {
                errorMessage = "Failed to save changes: \(error.localizedDescription)"
                print("ERROR [PhotoEditViewModel]: Failed to save changes: \(error.localizedDescription)")
            }
            
            isSaving = false
        }
    }
}
