//
//  DocumentsView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import UIKit

struct DocumentsView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        DocumentsViewContent(authService: authService)
    }
}

private struct DocumentsViewContent: View {
    let authService: AuthenticationService
    @StateObject private var viewModel: DocumentsViewModel
    @State private var editingDocument: Document? = nil
    @State private var showingDocumentOptions: Document? = nil
    
    init(authService: AuthenticationService) {
        self.authService = authService
        let databaseService = DatabaseService(client: SupabaseDatabaseClient())
        _viewModel = StateObject(wrappedValue: DocumentsViewModel(
            databaseService: databaseService,
            authService: authService
        ))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading documents...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel.loadDocuments()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if viewModel.documents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Documents")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Scan your first document to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.documents) { documentWithThumbnail in
                        DocumentRowView(
                            documentWithThumbnail: documentWithThumbnail,
                            onTap: {
                                editingDocument = documentWithThumbnail.document
                            },
                            onEllipsisTap: {
                                showingDocumentOptions = documentWithThumbnail.document
                            }
                        )
                    }
                }
            }
            .navigationTitle("Documents")
            .refreshable {
                viewModel.loadDocuments()
            }
            .onAppear {
                viewModel.loadDocuments()
            }
            .onChange(of: editingDocument) { oldValue, newValue in
                // When editingDocument becomes nil (fullScreenCover dismissed), reload documents
                if oldValue != nil && newValue == nil {
                    viewModel.loadDocuments()
                }
            }
            .fullScreenCover(item: $editingDocument) { document in
                DocumentEditView(document: document)
            }
            .sheet(item: $showingDocumentOptions) { document in
                DocumentOptionsView(
                    document: document,
                    viewModel: viewModel,
                    onDismiss: {
                        showingDocumentOptions = nil
                    }
                )
            }
        }
    }
}

private struct DocumentRowView: View {
    let documentWithThumbnail: DocumentWithThumbnail
    let onTap: () -> Void
    let onEllipsisTap: () -> Void
    
    private var document: Document {
        documentWithThumbnail.document
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            thumbnailView
                .frame(width: 60, height: 80)
                .cornerRadius(8)
            
            // Document Info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.headline)
                Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(formatDate(document.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if document.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            
            // Ellipsis button
            Button(action: {
                onEllipsisTap()
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var thumbnailView: some View {
        Group {
            if let thumbnailUrlString = documentWithThumbnail.thumbnailUrl,
               let thumbnailUrl = DatabaseService.cacheBustedURL(from: thumbnailUrlString) {
                AsyncImage(url: thumbnailUrl) { phase in
                    switch phase {
                    case .empty:
                        thumbnailPlaceholder
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 80)
                            .clipped()
                    case .failure:
                        thumbnailPlaceholder
                    @unknown default:
                        thumbnailPlaceholder
                    }
                }
            } else {
                thumbnailPlaceholder
            }
        }
    }
    
    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(width: 60, height: 80)
            .overlay {
                Image(systemName: "doc.text")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Document Options View

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
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Edit")
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
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Rename")
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
                                    .foregroundColor(.red)
                                    .frame(width: 30)
                                Text("Export to PDF")
                                Spacer()
                            }
                        }
                        
                        Button(action: {
                            exportFormat = .jpeg
                            exportDocument(format: .jpeg)
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                Text("Export to JPEG")
                                Spacer()
                            }
                        }
                        
                        Button(action: {
                            exportFormat = .png
                            exportDocument(format: .png)
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                    .foregroundColor(.purple)
                                    .frame(width: 30)
                                Text("Export to PNG")
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
                                .foregroundColor(.yellow)
                                .frame(width: 30)
                            Text(document.isFavorite ? "Remove from Favorites" : "Add to Favorites")
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

#Preview {
    DocumentsView()
        .environmentObject(AuthenticationService())
}
