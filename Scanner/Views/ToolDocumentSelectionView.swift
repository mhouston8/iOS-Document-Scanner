//
//  ToolDocumentSelectionView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct ToolDocumentSelectionView: View {
    @EnvironmentObject var authService: AuthenticationService
    let selectedToolTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: DocumentsViewModel
    @State private var selectedDocument: Document?
    
    init(selectedToolTitle: String, authService: AuthenticationService) {
        self.selectedToolTitle = selectedToolTitle
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
                // TODO: Open specific tool view with selected document
                // For now, just store the selection
                if let document = newValue {
                    print("Selected document: \(document.name) for tool: \(selectedToolTitle)")
                }
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
    ToolDocumentSelectionView(
        selectedToolTitle: "Edit",
        authService: AuthenticationService()
    )
    .environmentObject(AuthenticationService())
}
