//
//  DocumentOptionsView.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import UIKit

struct DocumentOptionsView: View {
    let document: Document
    @ObservedObject var viewModel: DocumentsViewModel
    let onDismiss: () -> Void
    
    @State private var showingRenameAlert = false
    @State private var newDocumentName = ""
    @State private var isExporting = false
    @State private var exportFileURLs: [URL] = []
    @State private var showingShareSheet = false
    @State private var exportFormat: ExportFormat = .jpeg
    
    enum ExportFormat {
        case pdf
        case jpeg
        case png
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Options List
                List {
                    // Edit
                    Button(action: {
                        // TODO: Open DocumentEditView
                        onDismiss()
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.primary)
                                .frame(width: 30)
                            Text("Edit")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    // Rename
                    Button(action: {
                        newDocumentName = document.name
                        showingRenameAlert = true
                    }) {
                        HStack {
                            Image(systemName: "pencil.line")
                                .foregroundColor(.primary)
                                .frame(width: 30)
                            Text("Rename")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    // Export Section
                    Section("Export") {
                        Button(action: {
                            exportFormat = .pdf
                            exportDocument(format: .pdf)
                        }) {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.primary)
                                    .frame(width: 30)
                                Text("Export to PDF")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        
                        Button(action: {
                            exportFormat = .jpeg
                            exportDocument(format: .jpeg)
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(.primary)
                                    .frame(width: 30)
                                Text("Export to JPEG")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        
                        Button(action: {
                            exportFormat = .png
                            exportDocument(format: .png)
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                    .foregroundColor(.primary)
                                    .frame(width: 30)
                                Text("Export to PNG")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                    
                    // Favorite/Unfavorite
                    Button(action: {
                        toggleFavorite()
                    }) {
                        HStack {
                            Image(systemName: document.isFavorite ? "star.fill" : "star")
                                .foregroundColor(.primary)
                                .frame(width: 30)
                            Text(document.isFavorite ? "Remove from Favorites" : "Add to Favorites")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    // Delete
                    Button(role: .destructive, action: {
                        deleteDocument()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 30)
                            Text("Delete")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView("Exporting...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                    }
                }
            }
            .alert("Rename Document", isPresented: $showingRenameAlert) {
                TextField("Document Name", text: $newDocumentName)
                Button("Cancel", role: .cancel) {}
                Button("Rename") {
                    renameDocument()
                }
            } message: {
                Text("Enter a new name for this document")
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: exportFileURLs)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    // MARK: - Actions
    
    private func renameDocument() {
        guard !newDocumentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            do {
                var updatedDocument = document
                updatedDocument.name = newDocumentName.trimmingCharacters(in: .whitespacesAndNewlines)
                updatedDocument.updatedAt = Date()
                
                try await viewModel.databaseService.updateDocumentInDatabase(updatedDocument)
                await MainActor.run {
                    viewModel.loadDocuments()
                    onDismiss()
                }
            } catch {
                print("ERROR [DocumentOptionsView]: Failed to rename document: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleFavorite() {
        Task {
            do {
                var updatedDocument = document
                updatedDocument.isFavorite.toggle()
                updatedDocument.updatedAt = Date()
                
                try await viewModel.databaseService.updateDocumentInDatabase(updatedDocument)
                await MainActor.run {
                    viewModel.loadDocuments()
                }
            } catch {
                print("ERROR [DocumentOptionsView]: Failed to toggle favorite: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteDocument() {
        Task {
            do {
                try await viewModel.databaseService.deleteDocumentFromDatabase(documentId: document.id)
                await MainActor.run {
                    viewModel.loadDocuments()
                    onDismiss()
                }
            } catch {
                print("ERROR [DocumentOptionsView]: Failed to delete document: \(error.localizedDescription)")
            }
        }
    }
    
    private func exportDocument(format: ExportFormat) {
        Task {
            isExporting = true
            
            do {
                // Load all pages and images
                let pages = try await viewModel.databaseService.readDocumentPagesFromDatabase(documentId: document.id)
                let sortedPages = pages.sorted { $0.pageNumber < $1.pageNumber }
                
                var images: [UIImage] = []
                for page in sortedPages {
                    guard let imageUrl = DatabaseService.cacheBustedURL(from: page.imageUrl) else {
                        continue
                    }
                    
                    var request = URLRequest(url: imageUrl)
                    request.cachePolicy = .reloadIgnoringLocalCacheData
                    
                    let (data, _) = try await URLSession.shared.data(for: request)
                    guard let image = UIImage(data: data) else {
                        continue
                    }
                    
                    images.append(image)
                }
                
                guard !images.isEmpty else {
                    isExporting = false
                    return
                }
                
                // Export using DocumentExportManager
                let exportManager = DocumentExportManager()
                let fileURLs: [URL]
                
                switch format {
                case .pdf:
                    let fileURL = try await exportManager.exportToPDF(images: images, documentName: document.name)
                    fileURLs = [fileURL]
                case .jpeg:
                    fileURLs = try await exportManager.exportToJPEG(images: images, documentName: document.name)
                case .png:
                    fileURLs = try await exportManager.exportToPNG(images: images, documentName: document.name)
                }
                
                await MainActor.run {
                    exportFileURLs = fileURLs
                    isExporting = false
                    showingShareSheet = true
                }
            } catch {
                print("ERROR [DocumentOptionsView]: Failed to export document: \(error.localizedDescription)")
                isExporting = false
            }
        }
    }
}
