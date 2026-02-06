//
//  MergePreviewView.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct MergePreviewView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    let documents: [Document]
    let databaseService: DatabaseService
    
    @State private var pagesWithImages: [(id: UUID, document: Document, page: DocumentPage, image: UIImage)] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingNamingDialog = false
    @State private var documentName = ""
    
    private let mergeManager: MergeManager
    
    init(documents: [Document], databaseService: DatabaseService) {
        self.documents = documents
        self.databaseService = databaseService
        self.mergeManager = MergeManager(databaseService: databaseService)
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
                } else if pagesWithImages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Pages")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Header Info
                        headerInfo
                            .padding()
                        
                        // Pages List (reorderable)
                        List {
                            ForEach(Array(pagesWithImages.enumerated()), id: \.element.id) { index, pageData in
                                pageRow(pageData: pageData, index: index)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                            .onMove { source, destination in
                                pagesWithImages.move(fromOffsets: source, toOffset: destination)
                            }
                        }
                        .listStyle(.plain)
                        .environment(\.editMode, .constant(.active))
                        
                        // Create Button
                        createButton
                            .padding()
                    }
                }
            }
            .navigationTitle("Arrange Pages")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if pagesWithImages.isEmpty {
                    loadPages()
                }
            }
            .sheet(isPresented: $showingNamingDialog) {
                DocumentNamingView(
                    documentName: $documentName,
                    pageCount: pagesWithImages.count,
                    onSave: {
                        createMergedDocument()
                    },
                    onCancel: {
                        documentName = ""
                        showingNamingDialog = false
                    }
                )
            }
        }
    }
    
    // MARK: - Header Info
    
    private var headerInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Arrange pages for merged document")
                .font(.headline)
            Text("\(pagesWithImages.count) page\(pagesWithImages.count == 1 ? "" : "s") • Drag to reorder • Tap to remove")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private func pageRow(pageData: (id: UUID, document: Document, page: DocumentPage, image: UIImage), index: Int) -> some View {
        HStack(spacing: 12) {
            // Page number indicator
            Text("\(index + 1)")
                .font(.headline)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            // Page thumbnail
            Image(uiImage: pageData.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 100)
                .clipped()
                .cornerRadius(8)
            
            // Page info
            VStack(alignment: .leading, spacing: 4) {
                Text("Page \(pageData.page.pageNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("From: \(pageData.document.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Remove button
            Button(action: {
                removePage(pageData.id)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 24))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Button(action: {
            documentName = generateDefaultDocumentName()
            showingNamingDialog = true
        }) {
            Text("Create Merged Document")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(pagesWithImages.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(12)
        }
        .disabled(pagesWithImages.isEmpty)
    }
    
    // MARK: - Loading
    
    private func loadPages() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                let loadedPages = try await mergeManager.loadPagesFromDocuments(documents)
                
                // Convert to our format with unique IDs
                pagesWithImages = loadedPages.map { (document, page, image) in
                    (id: UUID(), document: document, page: page, image: image)
                }
            } catch {
                errorMessage = error.localizedDescription
                print("ERROR [MergePreviewView]: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Actions
    
    private func removePage(_ pageId: UUID) {
        withAnimation {
            pagesWithImages.removeAll { $0.id == pageId }
        }
    }
    
    private func generateDefaultDocumentName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Merged Document \(formatter.string(from: Date()))"
    }
    
    private func createMergedDocument() {
        Task {
            do {
                guard let userId = await authService.currentUserId() else {
                    print("Error: No authenticated user")
                    return
                }
                
                // Convert back to format expected by MergeManager
                let pagesForMerge = pagesWithImages.map { pageData in
                    (document: pageData.document, page: pageData.page, image: pageData.image)
                }
                
                // Create merged document
                let mergedDocument = try await mergeManager.createMergedDocument(
                    userId: userId,
                    name: documentName,
                    pages: pagesForMerge
                )
                
                print("Successfully created merged document '\(documentName)' with \(pagesWithImages.count) pages")
                
                // Dismiss views
                showingNamingDialog = false
                dismiss()
            } catch {
                print("Error creating merged document: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    MergePreviewView(
        documents: [
            Document(userId: UUID(), name: "Doc 1", pageCount: 2),
            Document(userId: UUID(), name: "Doc 2", pageCount: 1)
        ],
        databaseService: DatabaseService(client: SupabaseDatabaseClient())
    )
    .environmentObject(AuthenticationService())
}
