//
//  HomeView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        HomeViewContent(authService: authService)
    }
}

private struct HomeViewContent: View {
    let authService: AuthenticationService
    @StateObject private var viewModel: HomeViewModel
    @State private var selectedCategory: Category = .scan
    @State private var editingDocument: Document? = nil
    @State private var showingMergeSelection = false
    @State private var showingSplitSelection = false
    
    enum Category: String, CaseIterable {
        case scan = "Scan"
        case pdf = "PDF"
        case edit = "Edit"
        case sign = "Sign"
        case organize = "Organize"
        
        var actions: [ActionItem] {
            switch self {
            case .scan:
                return [
                    ActionItem(icon: "sparkles", title: "Smart Scan", color: .purple),
                    ActionItem(icon: "photo", title: "Import Photos", color: .blue),
                    ActionItem(icon: "folder", title: "Import Files", color: .green)
                ]
            case .pdf:
                return [
                    ActionItem(icon: "doc.on.doc", title: "Merge", color: .blue),
                    ActionItem(icon: "doc.badge.plus", title: "Split", color: .indigo),
                    ActionItem(icon: "square.and.arrow.up", title: "Export", color: .green)
                ]
            case .edit:
                return [
                    ActionItem(icon: "pencil", title: "Edit", color: .blue),
                    ActionItem(icon: "crop", title: "Crop", color: .green),
                    ActionItem(icon: "rotate.left", title: "Rotate", color: .orange),
                    ActionItem(icon: "camera.filters", title: "Filters", color: .purple),
                    ActionItem(icon: "sun.max", title: "Adjust", color: .yellow),
                    ActionItem(icon: "eye.slash", title: "Remove BG", color: .red)
                ]
            case .sign:
                return [
                    ActionItem(icon: "signature", title: "Sign", color: .blue),
                    ActionItem(icon: "textformat", title: "Watermark", color: .cyan),
                    ActionItem(icon: "text.bubble", title: "Annotate", color: .orange)
                ]
            case .organize:
                return [
                    ActionItem(icon: "folder.badge.plus", title: "Folder", color: .blue),
                    ActionItem(icon: "tag", title: "Tags", color: .purple),
                    ActionItem(icon: "star", title: "Favorites", color: .yellow),
                    ActionItem(icon: "magnifyingglass", title: "Search", color: .gray)
                ]
            }
        }
    }
    
    init(authService: AuthenticationService) {
        self.authService = authService
        let databaseService = DatabaseService(client: SupabaseDatabaseClient())
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            databaseService: databaseService,
            authService: authService
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Category Tabs
                    categoryTabsSection
                    
                    // Actions for Selected Category (with "All" button as last card)
                    selectedCategoryActionsSection
                    
                    // Recent Documents
                    recentDocumentsSection
                }
                .padding()
            }
            .navigationTitle("Home")
            .onAppear {
                //if viewModel.recentDocuments.isEmpty {
                    viewModel.loadRecentDocuments()
                //}
            }
            .onChange(of: editingDocument) { oldValue, newValue in
                // editingDocument is the Document currently open in PhotoEditView
                // - When you tap a document to edit: editingDocument changes from nil → Document (we don't reload here)
                // - When you dismiss PhotoEditView (tap Done/swipe down): editingDocument changes from Document → nil
                // - newValue == nil means "no document is currently being edited" (editor was closed)
                // - This happens regardless of whether changes were saved or not
                // - We reload to show updated thumbnails after editing
                if oldValue != nil && newValue == nil {
                    viewModel.loadRecentDocuments()
                }
            }
            .fullScreenCover(item: $editingDocument) { document in
                DocumentEditView(document: document)
            }
            .navigationDestination(isPresented: $showingMergeSelection) {
                MergeDocumentSelectionView(authService: authService)
                    .environmentObject(authService)
            }
            .navigationDestination(isPresented: $showingSplitSelection) {
                SplitDocumentSelectionView(authService: authService)
                    .environmentObject(authService)
            }
        }
    }
    
    // MARK: - Action Handling
    
    private func handleAction(_ action: ActionItem) {
        if action.title == "Merge" {
            showingMergeSelection = true
        } else if action.title == "Split" {
            showingSplitSelection = true
        } else {
            // TODO: Handle other actions
            print("Action '\(action.title)' tapped - not yet implemented")
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadImageAndShowEditor(from recentDoc: RecentDocument) {
        editingDocument = recentDoc.document
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome")
                .font(.title)
                .fontWeight(.bold)
            Text("You have \(viewModel.documentCount) document\(viewModel.documentCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Category Tabs
    
    private var categoryTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Category.allCases, id: \.self) { category in
                    categoryTab(category: category)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func categoryTab(category: Category) -> some View {
        Button(action: {
            withAnimation {
                selectedCategory = category
            }
        }) {
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(selectedCategory == category ? .semibold : .regular)
                .foregroundColor(selectedCategory == category ? .blue : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selectedCategory == category
                        ? Color.blue.opacity(0.1)
                        : Color(.systemGray6)
                )
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Selected Category Actions
    
    private var selectedCategoryActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedCategory.rawValue + " Tools")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Show actions for selected category
                ForEach(selectedCategory.actions) { action in
                    actionButton(action: action)
                }
                
                // "All" button as last card
                NavigationLink(destination: DocumentToolsView()) {
                    allButton
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Recent Documents
    
    private var recentDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Documents")
                .font(.headline)
            
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if viewModel.recentDocuments.isEmpty {
                Text("No recent documents")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.recentDocuments) { recentDoc in
                            recentDocumentCard(recentDoc: recentDoc)
                                .contentShape(Rectangle()) //improves hit testing/tappable area
                                .onTapGesture {
                                    loadImageAndShowEditor(from: recentDoc)
                                }
                        }
                    }
                }
            }
        }
    }
    
    private func recentDocumentCard(recentDoc: RecentDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            if let thumbnailUrlString = recentDoc.thumbnailUrl,
               let thumbnailUrl = DatabaseService.cacheBustedURL(from: thumbnailUrlString) {
                AsyncImage(url: thumbnailUrl) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 120, height: 160)
                            .cornerRadius(8)
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 160)
                            .clipped()
                            .cornerRadius(8)
                    case .failure:
                        thumbnailPlaceholder
                    @unknown default:
                        thumbnailPlaceholder
                    }
                }
            } else {
                // No thumbnail URL available
                thumbnailPlaceholder
            }
            
            Text(recentDoc.document.name)
                .font(.caption)
                .lineLimit(1)
            Text(formatTimeAgo(recentDoc.document.createdAt))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 120)
    }
    
    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(width: 120, height: 160)
            .cornerRadius(8)
            .overlay {
                Image(systemName: "doc.text")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
            }
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Action Button
    
    private func actionButton(action: ActionItem) -> some View {
        Button(action: {
            handleAction(action)
        }) {
            VStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.system(size: 24))
                    .foregroundColor(action.color)
                
                Text(action.title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - All Button
    
    private var allButton: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            Text("All")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthenticationService())
    }
}
