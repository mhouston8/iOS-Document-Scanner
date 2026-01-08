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
    @State private var editingImage: UIImage? = nil
    
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
                    ActionItem(icon: "folder", title: "Import Files", color: .green),
                    ActionItem(icon: "person.text.rectangle", title: "ID Card", color: .orange)
                ]
            case .pdf:
                return [
                    ActionItem(icon: "doc.on.doc", title: "Merge", color: .blue),
                    ActionItem(icon: "doc.badge.plus", title: "Split", color: .indigo),
                    ActionItem(icon: "square.and.arrow.up", title: "Export", color: .green),
                    ActionItem(icon: "arrow.down.doc", title: "Compress", color: .gray)
                ]
            case .edit:
                return [
                    ActionItem(icon: "pencil", title: "Edit", color: .blue),
                    ActionItem(icon: "camera.filters", title: "Filters", color: .purple),
                    ActionItem(icon: "sun.max", title: "Adjust", color: .yellow),
                    ActionItem(icon: "eye.slash", title: "Remove BG", color: .red)
                ]
            case .sign:
                return [
                    ActionItem(icon: "signature", title: "Sign", color: .blue),
                    ActionItem(icon: "textformat", title: "Watermark", color: .cyan),
                    ActionItem(icon: "text.bubble", title: "Annotate", color: .orange),
                    ActionItem(icon: "eye.slash.fill", title: "Redact", color: .black)
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
                if viewModel.recentDocuments.isEmpty {
                    viewModel.loadRecentDocuments()
                }
            }
            .fullScreenCover(item: Binding(
                get: { editingImage.map { ImageWrapper(image: $0) } },
                set: { _ in editingImage = nil }
            )) { wrapper in
                PhotoEditView(images: [wrapper.image], editedImages: Binding(
                    get: { editingImage.map { [$0] } },
                    set: { newImages in
                        editingImage = newImages?.first
                    }
                ))
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadImageAndShowEditor(from recentDoc: RecentDocument) {
        print("DEBUG [HomeView]: Loading image for document \(recentDoc.document.id)")
        
        Task {
            do {
                let databaseService = DatabaseService(client: SupabaseDatabaseClient())
                
                if let firstPage = try await databaseService.fetchFirstPage(documentId: recentDoc.document.id) {
                    print("DEBUG [HomeView]: Got first page, imageUrl: \(firstPage.imageUrl)")
                    
                    if !firstPage.imageUrl.isEmpty, let imageUrl = URL(string: firstPage.imageUrl) {
                        print("DEBUG [HomeView]: Loading image from URL: \(imageUrl)")
                        
                        // Load image from URL
                        let (data, response) = try await URLSession.shared.data(from: imageUrl)
                        print("DEBUG [HomeView]: Got data, size: \(data.count) bytes")
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            print("DEBUG [HomeView]: HTTP status: \(httpResponse.statusCode)")
                        }
                        
                        if let image = UIImage(data: data) {
                            print("DEBUG [HomeView]: Successfully created UIImage, size: \(image.size)")
                            await MainActor.run {
                                editingImage = image
                                print("DEBUG [HomeView]: Set editingImage = image")
                            }
                        } else {
                            print("ERROR [HomeView]: Failed to create UIImage from data")
                        }
                    } else {
                        print("ERROR [HomeView]: Invalid image URL: \(firstPage.imageUrl)")
                    }
                } else {
                    print("ERROR [HomeView]: No first page found")
                }
            } catch {
                print("ERROR [HomeView]: Failed to load image: \(error)")
                print("ERROR [HomeView]: Error details: \(error.localizedDescription)")
            }
        }
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
                NavigationLink(destination: AllActionsView()) {
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
            if let thumbnailUrlString = recentDoc.thumbnailUrl, let thumbnailUrl = URL(string: thumbnailUrlString) {
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
            // TODO: Handle action
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

// Helper struct for fullScreenCover item binding
struct ImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthenticationService())
    }
}
