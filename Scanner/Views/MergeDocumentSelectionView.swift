//
//  MergeDocumentSelectionView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct MergeDocumentSelectionView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: DocumentsViewModel
    @State private var selectedDocuments: Set<UUID> = []
    @State private var showingMergePreview = false
    
    private let databaseService: DatabaseService
    
    init(authService: AuthenticationService) {
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
                        Text("You need at least 2 documents to merge")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Selected count header
                        if !selectedDocuments.isEmpty {
                            selectedCountHeader
                        }
                        
                        // Documents list
                        List(viewModel.documents) { documentWithThumbnail in
                            MergeDocumentRowView(
                                documentWithThumbnail: documentWithThumbnail,
                                isSelected: selectedDocuments.contains(documentWithThumbnail.document.id)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleSelection(documentWithThumbnail.document.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continue") {
                        showingMergePreview = true
                    }
                    .disabled(selectedDocuments.count < 2)
                }
            }
            .refreshable {
                viewModel.loadDocuments()
            }
            .onAppear {
                if viewModel.documents.isEmpty {
                    viewModel.loadDocuments()
                }
            }
            .navigationDestination(isPresented: $showingMergePreview) {
                if !selectedDocuments.isEmpty {
                    let selectedDocs = viewModel.documents
                        .filter { selectedDocuments.contains($0.document.id) }
                        .map { $0.document }
                    
                    MergePreviewView(
                        documents: selectedDocs,
                        databaseService: databaseService
                    )
                    .environmentObject(authService)
                }
            }
        }
    }
    
    // MARK: - Selected Count Header
    
    private var selectedCountHeader: some View {
        HStack {
            Text("\(selectedDocuments.count) document\(selectedDocuments.count == 1 ? "" : "s") selected")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if selectedDocuments.count >= 2 {
                Text("Ready to merge")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            } else {
                Text("Select \(2 - selectedDocuments.count) more")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Selection
    
    private func toggleSelection(_ documentId: UUID) {
        if selectedDocuments.contains(documentId) {
            selectedDocuments.remove(documentId)
        } else {
            selectedDocuments.insert(documentId)
        }
    }
}

// MARK: - Merge Document Row View

private struct MergeDocumentRowView: View {
    let documentWithThumbnail: DocumentWithThumbnail
    let isSelected: Bool
    
    private var document: Document {
        documentWithThumbnail.document
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.system(size: 24))
            
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
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
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
    MergeDocumentSelectionView(authService: AuthenticationService())
        .environmentObject(AuthenticationService())
}
