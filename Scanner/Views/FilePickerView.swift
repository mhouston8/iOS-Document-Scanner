//
//  FilePickerView.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct FilePickerView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) var dismiss
    
    var allowedContentTypes: [UTType] = [.image, .pdf]
    var allowsMultipleSelection: Bool = true
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowsMultipleSelection
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePickerView
        
        init(_ parent: FilePickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard !urls.isEmpty else {
                parent.dismiss()
                return
            }
            
            // Load images from selected URLs asynchronously
            Task {
                var loadedImages: [UIImage] = []
                
                for url in urls {
                    // Check if file is accessible (security-scoped resource)
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    // Determine file type and load accordingly
                    if let image = await loadImage(from: url) {
                        await MainActor.run {
                            loadedImages.append(image)
                        }
                    } else if let pdfImages = await loadPDFPages(from: url) {
                        await MainActor.run {
                            loadedImages.append(contentsOf: pdfImages)
                        }
                    }
                }
                
                await MainActor.run {
                    parent.selectedImages = loadedImages
                    parent.dismiss()
                }
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
        
        // MARK: - File Loading Helpers
        
        private func loadImage(from url: URL) async -> UIImage? {
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else {
                return nil
            }
            return image
        }
        
        private func loadPDFPages(from url: URL) async -> [UIImage]? {
            guard let pdfDocument = CGPDFDocument(url as CFURL) else {
                return nil
            }
            
            var images: [UIImage] = []
            let pageCount = pdfDocument.numberOfPages
            
            for pageIndex in 1...pageCount {
                guard let page = pdfDocument.page(at: pageIndex) else { continue }
                
                let pageRect = page.getBoxRect(.mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                
                let image = renderer.image { context in
                    context.cgContext.translateBy(x: 0, y: pageRect.size.height)
                    context.cgContext.scaleBy(x: 1.0, y: -1.0)
                    context.cgContext.drawPDFPage(page)
                }
                
                images.append(image)
            }
            
            return images.isEmpty ? nil : images
        }
    }
}
