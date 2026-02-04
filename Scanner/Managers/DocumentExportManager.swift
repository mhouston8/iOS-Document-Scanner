//
//  DocumentExportManager.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import UIKit

enum ExportError: LocalizedError {
    case noImagesProvided
    case failedToCreatePDF
    case failedToCreateImage
    case failedToWriteFile(String)
    
    var errorDescription: String? {
        switch self {
        case .noImagesProvided:
            return "No images provided for export"
        case .failedToCreatePDF:
            return "Failed to create PDF file"
        case .failedToCreateImage:
            return "Failed to create image file"
        case .failedToWriteFile(let reason):
            return "Failed to write file: \(reason)"
        }
    }
}

@MainActor
class DocumentExportManager {
    
    /// Exports images as a single PDF file
    /// - Parameters:
    ///   - images: Array of images to include in PDF (one per page)
    ///   - documentName: Name of the document (used for filename)
    /// - Returns: URL to the temporary PDF file
    func exportToPDF(images: [UIImage], documentName: String) async throws -> URL {
        guard !images.isEmpty else {
            throw ExportError.noImagesProvided
        }
        
        // Create temporary file URL
        let fileName = sanitizeFileName(documentName)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName).pdf")
        
        // Create PDF
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: CGSize(width: 612, height: 792))) // Letter size
        
        do {
            try pdfRenderer.writePDF(to: fileURL) { context in
                for image in images {
                    // Start a new page
                    context.beginPage()
                    
                    // Calculate size to fit image while maintaining aspect ratio
                    let imageSize = image.size
                    let pageRect = context.pdfContextBounds
                    let aspectRatio = imageSize.width / imageSize.height
                    
                    var drawRect: CGRect
                    if pageRect.width / pageRect.height > aspectRatio {
                        // Page is wider - fit to height
                        let width = pageRect.height * aspectRatio
                        drawRect = CGRect(
                            x: (pageRect.width - width) / 2,
                            y: 0,
                            width: width,
                            height: pageRect.height
                        )
                    } else {
                        // Page is taller - fit to width
                        let height = pageRect.width / aspectRatio
                        drawRect = CGRect(
                            x: 0,
                            y: (pageRect.height - height) / 2,
                            width: pageRect.width,
                            height: height
                        )
                    }
                    
                    // Draw image
                    image.draw(in: drawRect)
                }
            }
        } catch {
            throw ExportError.failedToCreatePDF
        }
        
        return fileURL
    }
    
    /// Exports images as JPEG files (one file per image)
    /// - Parameters:
    ///   - images: Array of images to export
    ///   - documentName: Name of the document (used for filename)
    ///   - quality: JPEG compression quality (0.0 to 1.0, default 0.8)
    /// - Returns: Array of URLs to temporary JPEG files
    func exportToJPEG(images: [UIImage], documentName: String, quality: CGFloat = 0.8) async throws -> [URL] {
        guard !images.isEmpty else {
            throw ExportError.noImagesProvided
        }
        
        let fileName = sanitizeFileName(documentName)
        var fileURLs: [URL] = []
        
        for (index, image) in images.enumerated() {
            // Create temporary file URL
            let fileURL: URL
            if images.count == 1 {
                fileURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(fileName).jpg")
            } else {
                fileURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(fileName)_Page\(index + 1).jpg")
            }
            
            // Convert image to JPEG data
            guard let jpegData = image.jpegData(compressionQuality: quality) else {
                throw ExportError.failedToCreateImage
            }
            
            // Write to file
            do {
                try jpegData.write(to: fileURL)
                fileURLs.append(fileURL)
            } catch {
                throw ExportError.failedToWriteFile(error.localizedDescription)
            }
        }
        
        return fileURLs
    }
    
    /// Exports images as PNG files (one file per image)
    /// - Parameters:
    ///   - images: Array of images to export
    ///   - documentName: Name of the document (used for filename)
    /// - Returns: Array of URLs to temporary PNG files
    func exportToPNG(images: [UIImage], documentName: String) async throws -> [URL] {
        guard !images.isEmpty else {
            throw ExportError.noImagesProvided
        }
        
        let fileName = sanitizeFileName(documentName)
        var fileURLs: [URL] = []
        
        for (index, image) in images.enumerated() {
            // Create temporary file URL
            let fileURL: URL
            if images.count == 1 {
                fileURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(fileName).png")
            } else {
                fileURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(fileName)_Page\(index + 1).png")
            }
            
            // Convert image to PNG data
            guard let pngData = image.pngData() else {
                throw ExportError.failedToCreateImage
            }
            
            // Write to file
            do {
                try pngData.write(to: fileURL)
                fileURLs.append(fileURL)
            } catch {
                throw ExportError.failedToWriteFile(error.localizedDescription)
            }
        }
        
        return fileURLs
    }
    
    // MARK: - Helper Methods
    
    /// Sanitizes a filename by removing invalid characters
    private func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
