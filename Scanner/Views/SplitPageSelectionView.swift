//
//  SplitPageSelectionView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import UIKit

struct SplitPageSelectionView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    let document: Document
    let databaseService: DatabaseService
    
    @State private var pages: [DocumentPage] = []
    @State private var selectedPageIds: Set<UUID> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingNamingDialog = false
    @State private var documentName = ""
    @State private var selectedPageImages: [UIImage] = []
    
    init(document: Document, databaseService: DatabaseService) {
        self.document = document
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
                    VStack(spacing: 0) {
                        // Instruction label
                        instructionLabel
                        
                        // Selected count header
                        if !selectedPageIds.isEmpty {
                            selectedCountHeader
                        }
                        
                        // Pages list
                        GeometryReader { geometry in
                            ScrollView {
                                let padding: CGFloat = 16
                                let spacing: CGFloat = 2
                                let availableWidth = geometry.size.width - (padding * 2)
                                let itemSize = (availableWidth - spacing) / 2
                                
                                LazyVGrid(columns: [
                                    GridItem(.fixed(itemSize), spacing: spacing),
                                    GridItem(.fixed(itemSize), spacing: spacing)
                                ], spacing: spacing) {
                                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                                        pageThumbnail(page: page, index: index, itemSize: itemSize)
                                    }
                                }
                                .padding(.horizontal, padding)
                                .padding(.top)
                            }
                        }
                        
                        // Extract button
                        if !selectedPageIds.isEmpty {
                            extractButton
                                .padding()
                        }
                    }
                }
            }
            .navigationTitle("Select Pages")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if pages.isEmpty {
                    loadPages()
                }
            }
            .sheet(isPresented: $showingNamingDialog) {
                DocumentNamingView(
                    documentName: $documentName,
                    pageCount: selectedPageIds.count,
                    onSave: {
                        createExtractedDocument()
                    },
                    onCancel: {
                        documentName = ""
                        showingNamingDialog = false
                    }
                )
            }
        }
    }
    
    // MARK: - Instruction Label
    
    private var instructionLabel: some View {
        VStack(spacing: 8) {
            Text("Select pages to extract")
                .font(.headline)
            Text("Choose pages to extract into a new document")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Selected Count Header
    
    private var selectedCountHeader: some View {
        HStack {
            Text("\(selectedPageIds.count) page\(selectedPageIds.count == 1 ? "" : "s") selected")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if selectedPageIds.count >= 1 {
                Text("Ready to extract")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Page Thumbnail
    
    private func pageThumbnail(page: DocumentPage, index: Int, itemSize: CGFloat) -> some View {
        Button(action: {
            toggleSelection(page.id)
        }) {
            VStack(spacing: 8) {
                // Selection indicator overlay
                ZStack(alignment: .topTrailing) {
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
                    .frame(width: itemSize - 32, height: itemSize - 32) // Account for VStack padding (8*2 = 16) + some margin
                    .clipped()
                    .cornerRadius(8)
                    
                    // Selection indicator
                    Image(systemName: selectedPageIds.contains(page.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedPageIds.contains(page.id) ? .blue : .white)
                        .font(.system(size: 24))
                        .padding(8)
                        .background(selectedPageIds.contains(page.id) ? Color.white.opacity(0.9) : Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                // Page Number
                Text("Page \(page.pageNumber)")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(width: itemSize - 16, height: itemSize - 16) // Account for padding
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedPageIds.contains(page.id) ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedPageIds.contains(page.id) ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
    
    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "doc.text")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Extract Button
    
    private var extractButton: some View {
        Button(action: {
            loadSelectedPageImages()
        }) {
            Text("Extract Pages")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
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
                
                // Debug: Log page information
                print("DEBUG [SplitPageSelectionView]: Loaded \(pages.count) pages for document '\(document.name)'")
                for (index, page) in pages.enumerated() {
                    print("DEBUG [SplitPageSelectionView]: Page \(index): id=\(page.id.uuidString.prefix(8)), pageNumber=\(page.pageNumber)")
                }
            } catch {
                errorMessage = "Failed to load pages: \(error.localizedDescription)"
                print("ERROR [SplitPageSelectionView]: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Selection
    
    private func toggleSelection(_ pageId: UUID) {
        if selectedPageIds.contains(pageId) {
            selectedPageIds.remove(pageId)
        } else {
            selectedPageIds.insert(pageId)
        }
    }
    
    // MARK: - Extract Document
    
    private func loadSelectedPageImages() {
        Task {
            isLoading = true
            
            do {
                var images: [UIImage] = []
                let selectedPages = pages.filter { selectedPageIds.contains($0.id) }
                
                for page in selectedPages.sorted(by: { $0.pageNumber < $1.pageNumber }) {
                    guard let imageUrl = DatabaseService.cacheBustedURL(from: page.imageUrl) else {
                        continue
                    }
                    
                    var request = URLRequest(url: imageUrl)
                    request.cachePolicy = .reloadIgnoringLocalCacheData
                    
                    let (data, _) = try await URLSession.shared.data(for: request)
                    if let image = UIImage(data: data) {
                        images.append(image)
                    }
                }
                
                await MainActor.run {
                    selectedPageImages = images
                    documentName = generateDefaultDocumentName()
                    showingNamingDialog = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load page images: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func createExtractedDocument() {
        Task {
            do {
                guard let userId = await authService.currentUserId() else {
                    print("Error: No authenticated user")
                    return
                }
                
                // Calculate file size
                let fileSize = selectedPageImages.reduce(Int64(0)) { total, image in
                    let imageDataSize = image.jpegData(compressionQuality: 0.8)?.count ?? 0
                    return total + Int64(imageDataSize)
                }
                
                // Create document model
                let extractedDocument = Document(
                    userId: userId,
                    name: documentName,
                    pageCount: selectedPageImages.count,
                    fileSize: fileSize
                )
                
                // Save document and pages
                try await databaseService.createDocument(extractedDocument, pages: selectedPageImages)
                
                print("Successfully created extracted document '\(documentName)' with \(selectedPageImages.count) pages")
                
                // Dismiss views
                showingNamingDialog = false
                dismiss()
            } catch {
                print("Error creating extracted document: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func generateDefaultDocumentName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "\(document.name) - Extracted \(formatter.string(from: Date()))"
    }
}

#Preview {
    SplitPageSelectionView(
        document: Document(
            userId: UUID(),
            name: "Sample Document",
            pageCount: 5
        ),
        databaseService: DatabaseService(client: SupabaseDatabaseClient())
    )
    .environmentObject(AuthenticationService())
}
