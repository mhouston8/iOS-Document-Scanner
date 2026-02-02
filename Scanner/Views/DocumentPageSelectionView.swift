//
//  DocumentPageSelectionView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import UIKit

struct DocumentPageSelectionView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    let document: Document
    let toolTitle: String
    let databaseService: DatabaseService
    
    @State private var pages: [DocumentPage] = []
    @State private var selectedPageIndex: Int?
    @State private var isLoading = false
    @State private var errorMessage: String?
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
    
    init(document: Document, toolTitle: String, databaseService: DatabaseService) {
        self.document = document
        self.toolTitle = toolTitle
        self.databaseService = databaseService
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading pages...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            loadPages()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if pages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Pages")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("This document has no pages")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header Info
                            headerInfo
                            
                            // Page Grid
                            pageGrid
                            
                            // Continue Button
                            if selectedPageIndex != nil {
                                continueButton
                                    .padding(.top, 8)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Page")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if pages.isEmpty {
                    loadPages()
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
    
    // MARK: - Header Info
    
    private var headerInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(document.name)
                .font(.headline)
            Text("Applying \(toolTitle) to page")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Page Grid
    
    private var pageGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                pageThumbnail(page: page, index: index)
            }
        }
    }
    
    private func pageThumbnail(page: DocumentPage, index: Int) -> some View {
        Button(action: {
            selectedPageIndex = index
        }) {
            VStack(spacing: 8) {
                // Thumbnail Image
                Group {
                    if let thumbnailUrlString = page.thumbnailUrl,
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
                            case .failure:
                                thumbnailPlaceholder
                            @unknown default:
                                thumbnailPlaceholder
                            }
                        }
                    } else if let imageUrl = DatabaseService.cacheBustedURL(from: page.imageUrl) {
                        AsyncImage(url: imageUrl) { phase in
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
                .frame(height: 150)
                .clipped()
                .cornerRadius(8)
                
                // Page Number
                Text("Page \(page.pageNumber)")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedPageIndex == index ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedPageIndex == index ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "doc.text")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
            }
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button(action: {
            guard let selectedIndex = selectedPageIndex,
                  selectedIndex < pages.count else { return }
            
            let selectedPage = pages[selectedIndex]
            
            // Handle Crop tool
            if toolTitle == "Crop" {
                loadPageImageForCrop(page: selectedPage)
            } else if toolTitle == "Filters" {
                loadPageImageForFilters(page: selectedPage)
            } else if toolTitle == "Watermark" {
                loadPageImageForWatermark(page: selectedPage)
            } else if toolTitle == "Sign" {
                loadPageImageForSign(page: selectedPage)
            } else if toolTitle == "Annotate" {
                loadPageImageForAnnotate(page: selectedPage)
            } else {
                // TODO: Handle other tools
                print("Selected page \(selectedPage.pageNumber) for tool: \(toolTitle)")
            }
        }) {
            Text("Continue")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Crop Handling
    
    private func loadPageImageForCrop(page: DocumentPage) {
        Task {
            isLoadingImage = true
            do {
                guard let imageUrl = DatabaseService.cacheBustedURL(from: page.imageUrl) else {
                    print("ERROR [DocumentPageSelectionView]: Invalid image URL")
                    isLoadingImage = false
                    return
                }
                
                var request = URLRequest(url: imageUrl)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let image = UIImage(data: data) else {
                    print("ERROR [DocumentPageSelectionView]: Failed to create UIImage")
                    isLoadingImage = false
                    return
                }
                
                await MainActor.run {
                    cropImage = image
                    cropPage = page
                    showingCropView = true
                    isLoadingImage = false
                }
            } catch {
                print("ERROR [DocumentPageSelectionView]: Failed to load image: \(error.localizedDescription)")
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
                var updatedDocument = document
                updatedDocument.updatedAt = Date()
                try await databaseService.updateDocumentInDatabase(updatedDocument)
                
                await MainActor.run {
                    showingCropView = false
                    cropImage = nil
                    cropPage = nil
                    selectedPageIndex = nil
                }
            } catch {
                print("ERROR [DocumentPageSelectionView]: Failed to save cropped image: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Filters Handling
    
    private func loadPageImageForFilters(page: DocumentPage) {
        Task {
            isLoadingImage = true
            do {
                guard let imageUrl = DatabaseService.cacheBustedURL(from: page.imageUrl) else {
                    print("ERROR [DocumentPageSelectionView]: Invalid image URL")
                    isLoadingImage = false
                    return
                }
                
                var request = URLRequest(url: imageUrl)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let image = UIImage(data: data) else {
                    print("ERROR [DocumentPageSelectionView]: Failed to create UIImage")
                    isLoadingImage = false
                    return
                }
                
                await MainActor.run {
                    filterImage = image
                    filterPage = page
                    showingFiltersView = true
                    isLoadingImage = false
                }
            } catch {
                print("ERROR [DocumentPageSelectionView]: Failed to load image: \(error.localizedDescription)")
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
                var updatedDocument = document
                updatedDocument.updatedAt = Date()
                try await databaseService.updateDocumentInDatabase(updatedDocument)
                
                await MainActor.run {
                    showingFiltersView = false
                    filterImage = nil
                    filterPage = nil
                    selectedPageIndex = nil
                }
            } catch {
                print("ERROR [DocumentPageSelectionView]: Failed to save filtered image: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Watermark Handling
    
    private func loadPageImageForWatermark(page: DocumentPage) {
        Task {
            isLoadingImage = true
            do {
                guard let imageUrl = DatabaseService.cacheBustedURL(from: page.imageUrl) else {
                    print("ERROR [DocumentPageSelectionView]: Invalid image URL")
                    isLoadingImage = false
                    return
                }
                
                var request = URLRequest(url: imageUrl)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let image = UIImage(data: data) else {
                    print("ERROR [DocumentPageSelectionView]: Failed to create UIImage")
                    isLoadingImage = false
                    return
                }
                
                await MainActor.run {
                    watermarkImage = image
                    watermarkPage = page
                    showingWatermarkView = true
                    isLoadingImage = false
                }
            } catch {
                print("ERROR [DocumentPageSelectionView]: Failed to load image: \(error.localizedDescription)")
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
                var updatedDocument = document
                updatedDocument.updatedAt = Date()
                try await databaseService.updateDocumentInDatabase(updatedDocument)
                
                await MainActor.run {
                    showingWatermarkView = false
                    watermarkImage = nil
                    watermarkPage = nil
                    selectedPageIndex = nil
                }
            } catch {
                print("ERROR [DocumentPageSelectionView]: Failed to save watermarked image: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sign Handling
    
    private func loadPageImageForSign(page: DocumentPage) {
        Task {
            isLoadingImage = true
            do {
                guard let imageUrl = DatabaseService.cacheBustedURL(from: page.imageUrl) else {
                    print("ERROR [DocumentPageSelectionView]: Invalid image URL")
                    isLoadingImage = false
                    return
                }
                
                var request = URLRequest(url: imageUrl)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let image = UIImage(data: data) else {
                    print("ERROR [DocumentPageSelectionView]: Failed to create UIImage")
                    isLoadingImage = false
                    return
                }
                
                await MainActor.run {
                    signImage = image
                    signPage = page
                    showingSignView = true
                    isLoadingImage = false
                }
            } catch {
                print("ERROR [DocumentPageSelectionView]: Failed to load image: \(error.localizedDescription)")
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
                var updatedDocument = document
                updatedDocument.updatedAt = Date()
                try await databaseService.updateDocumentInDatabase(updatedDocument)
                
                await MainActor.run {
                    showingSignView = false
                    signImage = nil
                    signPage = nil
                    selectedPageIndex = nil
                }
            } catch {
                print("ERROR [DocumentPageSelectionView]: Failed to save signed image: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Annotate Handling
    
    private func loadPageImageForAnnotate(page: DocumentPage) {
        Task {
            isLoadingImage = true
            do {
                guard let imageUrl = DatabaseService.cacheBustedURL(from: page.imageUrl) else {
                    print("ERROR [DocumentPageSelectionView]: Invalid image URL")
                    isLoadingImage = false
                    return
                }
                
                var request = URLRequest(url: imageUrl)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let image = UIImage(data: data) else {
                    print("ERROR [DocumentPageSelectionView]: Failed to create UIImage")
                    isLoadingImage = false
                    return
                }
                
                await MainActor.run {
                    annotateImage = image
                    annotatePage = page
                    showingAnnotateView = true
                    isLoadingImage = false
                }
            } catch {
                print("ERROR [DocumentPageSelectionView]: Failed to load image: \(error.localizedDescription)")
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
                var updatedDocument = document
                updatedDocument.updatedAt = Date()
                try await databaseService.updateDocumentInDatabase(updatedDocument)
                
                await MainActor.run {
                    showingAnnotateView = false
                    annotateImage = nil
                    annotatePage = nil
                    selectedPageIndex = nil
                }
            } catch {
                print("ERROR [DocumentPageSelectionView]: Failed to save annotated image: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Loading
    
    private func loadPages() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                let fetchedPages = try await databaseService.readDocumentPagesFromDatabase(documentId: document.id)
                pages = fetchedPages.sorted { $0.pageNumber < $1.pageNumber }
            } catch {
                errorMessage = "Failed to load pages: \(error.localizedDescription)"
                print("ERROR [DocumentPageSelectionView]: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
}

#Preview {
    DocumentPageSelectionView(
        document: Document(
            userId: UUID(),
            name: "Sample Document",
            pageCount: 3
        ),
        toolTitle: "Crop",
        databaseService: DatabaseService(client: SupabaseDatabaseClient())
    )
    .environmentObject(AuthenticationService())
}
