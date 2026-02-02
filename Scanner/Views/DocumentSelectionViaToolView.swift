//
//  DocumentSelectionViaToolView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import UIKit

struct DocumentSelectionViaToolView: View {
    @EnvironmentObject var authService: AuthenticationService
    let selectedToolTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: DocumentsViewModel
    @State private var selectedDocument: Document?
    @State private var showingPageSelection = false
    @State private var showingCropView = false
    @State private var cropImage: UIImage?
    @State private var cropPage: DocumentPage?
    @State private var showingFiltersView = false
    @State private var filterImage: UIImage?
    @State private var filterPage: DocumentPage?
    @State private var showingWatermarkView = false
    @State private var watermarkImage: UIImage?
    @State private var watermarkPage: DocumentPage?
    @State private var showingSignView = false
    @State private var signImage: UIImage?
    @State private var signPage: DocumentPage?
    @State private var showingAnnotateView = false
    @State private var annotateImage: UIImage?
    @State private var annotatePage: DocumentPage?
    @State private var isLoadingImage = false
    
    private let databaseService: DatabaseService
    
    init(selectedToolTitle: String, authService: AuthenticationService) {
        self.selectedToolTitle = selectedToolTitle
        let dbService = DatabaseService(client: SupabaseDatabaseClient())
        self.databaseService = dbService
        _viewModel = StateObject(wrappedValue: DocumentsViewModel(
            databaseService: dbService,
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
                        DocumentRowView(documentWithThumbnail: documentWithThumbnail)
                            .onTapGesture {
                                selectedDocument = documentWithThumbnail.document
                            }
                    }
                }
            }
            .navigationTitle("Select Document")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.loadDocuments()
            }
            .onAppear {
                if viewModel.documents.isEmpty {
                    viewModel.loadDocuments()
                }
            }
            .onChange(of: selectedDocument) { oldValue, newValue in
                guard let document = newValue else { return }
                
                // If multi-page document, show page selection
                if document.pageCount > 1 {
                    showingPageSelection = true
                } else {
                    // Single page document - load first page and open tool view
                    if selectedToolTitle == "Crop" {
                        loadFirstPageForCrop(document: document)
                    } else if selectedToolTitle == "Filters" {
                        loadFirstPageForFilters(document: document)
                    } else if selectedToolTitle == "Watermark" {
                        loadFirstPageForWatermark(document: document)
                    } else if selectedToolTitle == "Sign" {
                        loadFirstPageForSign(document: document)
                    } else if selectedToolTitle == "Annotate" {
                        loadFirstPageForAnnotate(document: document)
                    } else {
                        // TODO: Handle other tools
                        print("Selected single-page document: \(document.name) for tool: \(selectedToolTitle)")
                    }
                }
            }
            .overlay {
                if isLoadingImage {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView("Loading image...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                    }
                }
            }
            .navigationDestination(isPresented: $showingPageSelection) {
                if let document = selectedDocument {
                    DocumentPageSelectionView(
                        document: document,
                        toolTitle: selectedToolTitle,
                        databaseService: databaseService
                    )
                    .environmentObject(authService)
                }
            }
            .fullScreenCover(isPresented: $showingCropView) {
                if let image = cropImage {
                    CropView(
                        image: image,
                        editedImage: Binding(
                            get: { self.cropImage },
                            set: { newImage in
                                if let newImage = newImage {
                                    saveCroppedImage(newImage)
                                }
                            }
                        )
                    )
                }
            }
            .fullScreenCover(isPresented: $showingFiltersView) {
                if let image = filterImage {
                    FiltersView(
                        image: image,
                        editedImage: Binding(
                            get: { self.filterImage },
                            set: { newImage in
                                if let newImage = newImage {
                                    saveFilteredImage(newImage)
                                }
                            }
                        )
                    )
                }
            }
            .fullScreenCover(isPresented: $showingWatermarkView) {
                if let image = watermarkImage {
                    WatermarkView(
                        image: image,
                        editedImage: Binding(
                            get: { self.watermarkImage },
                            set: { newImage in
                                if let newImage = newImage {
                                    saveWatermarkedImage(newImage)
                                }
                            }
                        )
                    )
                }
            }
            .fullScreenCover(isPresented: $showingSignView) {
                if let image = signImage {
                    SignView(
                        image: image,
                        editedImage: Binding(
                            get: { self.signImage },
                            set: { newImage in
                                if let newImage = newImage {
                                    saveSignedImage(newImage)
                                }
                            }
                        )
                    )
                }
            }
            .fullScreenCover(isPresented: $showingAnnotateView) {
                if let image = annotateImage {
                    AnnotateView(
                        image: image,
                        editedImage: Binding(
                            get: { self.annotateImage },
                            set: { newImage in
                                if let newImage = newImage {
                                    saveAnnotatedImage(newImage)
                                }
                            }
                        )
                    )
                }
            }
        }
    }
    
    // MARK: - Crop Handling
    
    private func loadFirstPageForCrop(document: Document) {
        Task {
            isLoadingImage = true
            do {
                // Load pages for the document
                let pages = try await databaseService.readDocumentPagesFromDatabase(documentId: document.id)
                guard let firstPage = pages.sorted(by: { $0.pageNumber < $1.pageNumber }).first else {
                    print("ERROR [DocumentSelectionViaToolView]: No pages found for document")
                    isLoadingImage = false
                    return
                }
                
                // Load the image
                guard let imageUrl = DatabaseService.cacheBustedURL(from: firstPage.imageUrl) else {
                    print("ERROR [DocumentSelectionViaToolView]: Invalid image URL")
                    isLoadingImage = false
                    return
                }
                
                var request = URLRequest(url: imageUrl)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let image = UIImage(data: data) else {
                    print("ERROR [DocumentSelectionViaToolView]: Failed to create UIImage")
                    isLoadingImage = false
                    return
                }
                
                await MainActor.run {
                    cropImage = image
                    cropPage = firstPage
                    showingCropView = true
                    isLoadingImage = false
                }
            } catch {
                print("ERROR [DocumentSelectionViaToolView]: Failed to load page: \(error.localizedDescription)")
                isLoadingImage = false
            }
        }
    }
    
    private func saveCroppedImage(_ croppedImage: UIImage) {
        guard let page = cropPage else { return }
        
        Task {
            do {
                // Update the page in storage
                let urls = try await databaseService.updateDocumentPageInStorage(page, image: croppedImage)
                
                // Update the page record
                var updatedPage = page
                updatedPage.imageUrl = urls.imageUrl
                updatedPage.thumbnailUrl = urls.thumbnailUrl
                
                // Update in database
                try await databaseService.updateDocumentPagesInDatabase([updatedPage])
                
                // Update document timestamp
                if let document = selectedDocument {
                    var updatedDocument = document
                    updatedDocument.updatedAt = Date()
                    try await databaseService.updateDocumentInDatabase(updatedDocument)
                }
                
                await MainActor.run {
                    showingCropView = false
                    cropImage = nil
                    cropPage = nil
                    selectedDocument = nil
                }
            } catch {
                print("ERROR [DocumentSelectionViaToolView]: Failed to save cropped image: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Filters Handling
    
    private func loadFirstPageForFilters(document: Document) {
        Task {
            isLoadingImage = true
            do {
                // Load pages for the document
                let pages = try await databaseService.readDocumentPagesFromDatabase(documentId: document.id)
                guard let firstPage = pages.sorted(by: { $0.pageNumber < $1.pageNumber }).first else {
                    print("ERROR [DocumentSelectionViaToolView]: No pages found for document")
                    isLoadingImage = false
                    return
                }
                
                // Load the image
                guard let imageUrl = DatabaseService.cacheBustedURL(from: firstPage.imageUrl) else {
                    print("ERROR [DocumentSelectionViaToolView]: Invalid image URL")
                    isLoadingImage = false
                    return
                }
                
                var request = URLRequest(url: imageUrl)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let image = UIImage(data: data) else {
                    print("ERROR [DocumentSelectionViaToolView]: Failed to create UIImage")
                    isLoadingImage = false
                    return
                }
                
                await MainActor.run {
                    filterImage = image
                    filterPage = firstPage
                    showingFiltersView = true
                    isLoadingImage = false
                }
            } catch {
                print("ERROR [DocumentSelectionViaToolView]: Failed to load page: \(error.localizedDescription)")
                isLoadingImage = false
            }
        }
    }
    
    private func saveFilteredImage(_ filteredImage: UIImage) {
        guard let page = filterPage else { return }
        
        Task {
            do {
                // Update the page in storage
                let urls = try await databaseService.updateDocumentPageInStorage(page, image: filteredImage)
                
                // Update the page record
                var updatedPage = page
                updatedPage.imageUrl = urls.imageUrl
                updatedPage.thumbnailUrl = urls.thumbnailUrl
                
                // Update in database
                try await databaseService.updateDocumentPagesInDatabase([updatedPage])
                
                // Update document timestamp
                if let document = selectedDocument {
                    var updatedDocument = document
                    updatedDocument.updatedAt = Date()
                    try await databaseService.updateDocumentInDatabase(updatedDocument)
                }
                
                await MainActor.run {
                    showingFiltersView = false
                    filterImage = nil
                    filterPage = nil
                    selectedDocument = nil
                }
            } catch {
                print("ERROR [DocumentSelectionViaToolView]: Failed to save filtered image: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Watermark Handling
    
    private func loadFirstPageForWatermark(document: Document) {
        Task {
            isLoadingImage = true
            do {
                // Load pages for the document
                let pages = try await databaseService.readDocumentPagesFromDatabase(documentId: document.id)
                guard let firstPage = pages.sorted(by: { $0.pageNumber < $1.pageNumber }).first else {
                    print("ERROR [DocumentSelectionViaToolView]: No pages found for document")
                    isLoadingImage = false
                    return
                }
                
                // Load the image
                guard let imageUrl = DatabaseService.cacheBustedURL(from: firstPage.imageUrl) else {
                    print("ERROR [DocumentSelectionViaToolView]: Invalid image URL")
                    isLoadingImage = false
                    return
                }
                
                var request = URLRequest(url: imageUrl)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let image = UIImage(data: data) else {
                    print("ERROR [DocumentSelectionViaToolView]: Failed to create UIImage")
                    isLoadingImage = false
                    return
                }
                
                await MainActor.run {
                    watermarkImage = image
                    watermarkPage = firstPage
                    showingWatermarkView = true
                    isLoadingImage = false
                }
            } catch {
                print("ERROR [DocumentSelectionViaToolView]: Failed to load page: \(error.localizedDescription)")
                isLoadingImage = false
            }
        }
    }
    
    private func saveWatermarkedImage(_ watermarkedImage: UIImage) {
        guard let page = watermarkPage else { return }
        
        Task {
            do {
                // Update the page in storage
                let urls = try await databaseService.updateDocumentPageInStorage(page, image: watermarkedImage)
                
                // Update the page record
                var updatedPage = page
                updatedPage.imageUrl = urls.imageUrl
                updatedPage.thumbnailUrl = urls.thumbnailUrl
                
                // Update in database
                try await databaseService.updateDocumentPagesInDatabase([updatedPage])
                
                // Update document timestamp
                if let document = selectedDocument {
                    var updatedDocument = document
                    updatedDocument.updatedAt = Date()
                    try await databaseService.updateDocumentInDatabase(updatedDocument)
                }
                
                await MainActor.run {
                    showingWatermarkView = false
                    watermarkImage = nil
                    watermarkPage = nil
                    selectedDocument = nil
                }
            } catch {
                print("ERROR [DocumentSelectionViaToolView]: Failed to save watermarked image: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sign Handling
    
    private func loadFirstPageForSign(document: Document) {
        Task {
            isLoadingImage = true
            do {
                // Load pages for the document
                let pages = try await databaseService.readDocumentPagesFromDatabase(documentId: document.id)
                guard let firstPage = pages.sorted(by: { $0.pageNumber < $1.pageNumber }).first else {
                    print("ERROR [DocumentSelectionViaToolView]: No pages found for document")
                    isLoadingImage = false
                    return
                }
                
                // Load the image
                guard let imageUrl = DatabaseService.cacheBustedURL(from: firstPage.imageUrl) else {
                    print("ERROR [DocumentSelectionViaToolView]: Invalid image URL")
                    isLoadingImage = false
                    return
                }
                
                var request = URLRequest(url: imageUrl)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let image = UIImage(data: data) else {
                    print("ERROR [DocumentSelectionViaToolView]: Failed to create UIImage")
                    isLoadingImage = false
                    return
                }
                
                await MainActor.run {
                    signImage = image
                    signPage = firstPage
                    showingSignView = true
                    isLoadingImage = false
                }
            } catch {
                print("ERROR [DocumentSelectionViaToolView]: Failed to load page: \(error.localizedDescription)")
                isLoadingImage = false
            }
        }
    }
    
    private func saveSignedImage(_ signedImage: UIImage) {
        guard let page = signPage else { return }
        
        Task {
            do {
                // Update the page in storage
                let urls = try await databaseService.updateDocumentPageInStorage(page, image: signedImage)
                
                // Update the page record
                var updatedPage = page
                updatedPage.imageUrl = urls.imageUrl
                updatedPage.thumbnailUrl = urls.thumbnailUrl
                
                // Update in database
                try await databaseService.updateDocumentPagesInDatabase([updatedPage])
                
                // Update document timestamp
                if let document = selectedDocument {
                    var updatedDocument = document
                    updatedDocument.updatedAt = Date()
                    try await databaseService.updateDocumentInDatabase(updatedDocument)
                }
                
                await MainActor.run {
                    showingSignView = false
                    signImage = nil
                    signPage = nil
                    selectedDocument = nil
                }
            } catch {
                print("ERROR [DocumentSelectionViaToolView]: Failed to save signed image: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Annotate Handling
    
    private func loadFirstPageForAnnotate(document: Document) {
        Task {
            isLoadingImage = true
            do {
                // Load pages for the document
                let pages = try await databaseService.readDocumentPagesFromDatabase(documentId: document.id)
                guard let firstPage = pages.sorted(by: { $0.pageNumber < $1.pageNumber }).first else {
                    print("ERROR [DocumentSelectionViaToolView]: No pages found for document")
                    isLoadingImage = false
                    return
                }
                
                // Load the image
                guard let imageUrl = DatabaseService.cacheBustedURL(from: firstPage.imageUrl) else {
                    print("ERROR [DocumentSelectionViaToolView]: Invalid image URL")
                    isLoadingImage = false
                    return
                }
                
                var request = URLRequest(url: imageUrl)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let image = UIImage(data: data) else {
                    print("ERROR [DocumentSelectionViaToolView]: Failed to create UIImage")
                    isLoadingImage = false
                    return
                }
                
                await MainActor.run {
                    annotateImage = image
                    annotatePage = firstPage
                    showingAnnotateView = true
                    isLoadingImage = false
                }
            } catch {
                print("ERROR [DocumentSelectionViaToolView]: Failed to load page: \(error.localizedDescription)")
                isLoadingImage = false
            }
        }
    }
    
    private func saveAnnotatedImage(_ annotatedImage: UIImage) {
        guard let page = annotatePage else { return }
        
        Task {
            do {
                // Update the page in storage
                let urls = try await databaseService.updateDocumentPageInStorage(page, image: annotatedImage)
                
                // Update the page record
                var updatedPage = page
                updatedPage.imageUrl = urls.imageUrl
                updatedPage.thumbnailUrl = urls.thumbnailUrl
                
                // Update in database
                try await databaseService.updateDocumentPagesInDatabase([updatedPage])
                
                // Update document timestamp
                if let document = selectedDocument {
                    var updatedDocument = document
                    updatedDocument.updatedAt = Date()
                    try await databaseService.updateDocumentInDatabase(updatedDocument)
                }
                
                await MainActor.run {
                    showingAnnotateView = false
                    annotateImage = nil
                    annotatePage = nil
                    selectedDocument = nil
                }
            } catch {
                print("ERROR [DocumentSelectionViaToolView]: Failed to save annotated image: \(error.localizedDescription)")
            }
        }
    }
}

// Reuse DocumentRowView from DocumentsView
private struct DocumentRowView: View {
    let documentWithThumbnail: DocumentWithThumbnail
    
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
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
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

#Preview {
    DocumentSelectionViaToolView(
        selectedToolTitle: "Edit",
        authService: AuthenticationService()
    )
    .environmentObject(AuthenticationService())
}
