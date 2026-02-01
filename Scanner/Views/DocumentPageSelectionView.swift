//
//  DocumentPageSelectionView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

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
            // TODO: Open specific tool view with selected page
            if let selectedIndex = selectedPageIndex,
               selectedIndex < pages.count {
                let selectedPage = pages[selectedIndex]
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
