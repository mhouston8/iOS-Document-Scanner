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
                // Read all pages for the document
                let fetchedPages = try await databaseService.readDocumentPagesFromDatabase(documentId: document.id)
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
                // Only save pages that have been edited (compare editedImages with original images)
                var pagesToUpdate: [(page: DocumentPage, image: UIImage)] = []
                
                for (index, editedImage) in editedImages.enumerated() {
                    guard index < pages.count else { continue }
                    guard index < images.count else { continue }
                    
                    // Check if image was actually modified
                    let originalImage = images[index]
                    if !imagesAreEqual(originalImage, editedImage) {
                        pagesToUpdate.append((page: pages[index], image: editedImage))
                    }
                }
                
                // If no changes, just return
                guard !pagesToUpdate.isEmpty else {
                    hasUnsavedChanges = false
                    isSaving = false
                    return
                }
                
                // Upload edited images and prepare updated pages
                var updatedPages: [DocumentPage] = []
                
                for (page, editedImage) in pagesToUpdate {
                    // Upload the edited image and thumbnail (overwrites existing)
                    let urls = try await databaseService.uploadDocumentPageToStorage(page, image: editedImage)
                    
                    // Update the page record with new image URL and thumbnail URL
                    var updatedPage = page
                    updatedPage.imageUrl = urls.imageUrl
                    updatedPage.thumbnailUrl = urls.thumbnailUrl
                    
                    updatedPages.append(updatedPage)
                }
                
                // Batch update all pages in database
                if !updatedPages.isEmpty {
                    try await databaseService.updateDocumentPagesInDatabase(updatedPages)
                    
                    // Update local pages array
                    for updatedPage in updatedPages {
                        if let index = pages.firstIndex(where: { $0.id == updatedPage.id }) {
                            pages[index] = updatedPage
                        }
                    }
                }
                
                // Update document's updatedAt timestamp
                var updatedDocument = document
                updatedDocument.updatedAt = Date()
                try await databaseService.updateDocumentInDatabase(updatedDocument)
                
                // Update original images array to match edited images
                images = editedImages
                hasUnsavedChanges = false
                
                print("Successfully saved changes for document \(document.id) - updated \(pagesToUpdate.count) page(s)")
            } catch {
                errorMessage = "Failed to save changes: \(error.localizedDescription)"
                print("ERROR [PhotoEditViewModel]: Failed to save changes: \(error.localizedDescription)")
            }
            
            isSaving = false
        }
    }
    
    // MARK: - Helper Methods
    
    private func imagesAreEqual(_ image1: UIImage, _ image2: UIImage) -> Bool {
        // Simple comparison - if data is the same, images are the same
        guard let data1 = image1.jpegData(compressionQuality: 1.0),
              let data2 = image2.jpegData(compressionQuality: 1.0) else {
            return false
        }
        return data1 == data2
    }
    
}
