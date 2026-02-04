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

#Preview {
    DocumentsView()
        .environmentObject(AuthenticationService())
}
