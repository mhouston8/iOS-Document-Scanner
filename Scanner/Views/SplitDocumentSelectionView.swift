//
//  SplitDocumentSelectionView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct SplitDocumentSelectionView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: DocumentsViewModel
    @State private var selectedDocument: Document?
    @State private var showingPageSelection = false
    
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
                        Text("Select a document to split")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Instruction label
                        instructionLabel
                        
                        // Documents list
                        List(viewModel.documents) { documentWithThumbnail in
                            SplitDocumentRowView(
                                documentWithThumbnail: documentWithThumbnail,
                                isSelected: selectedDocument?.id == documentWithThumbnail.document.id
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDocument = documentWithThumbnail.document
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continue") {
                        showingPageSelection = true
                    }
                    .disabled(selectedDocument == nil)
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
            .navigationDestination(isPresented: $showingPageSelection) {
                if let document = selectedDocument {
                    // TODO: Navigate to SplitPageSelectionView
                    Text("Split Page Selection - Coming Soon")
                        .navigationTitle("Select Pages")
                }
            }
        }
    }
    
    // MARK: - Instruction Label
    
    private var instructionLabel: some View {
        VStack(spacing: 8) {
            Text("Select document to split")
                .font(.headline)
            Text("Choose a document to extract pages from")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
    }
}

// MARK: - Split Document Row View

private struct SplitDocumentRowView: View {
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
    SplitDocumentSelectionView(authService: AuthenticationService())
        .environmentObject(AuthenticationService())
}
