//
//  HomeViewOptionC.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

// Option C: Tabbed Categories - Horizontal tabs to switch between categories
struct HomeViewOptionC: View {
    @State private var selectedCategory: Category = .scan
    
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
                    ActionItem(icon: "camera.fill", title: "Scan", color: .blue),
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Large Scan Button
                scanButtonSection
                
                // Category Tabs
                categoryTabsSection
                
                // Actions for Selected Category
                selectedCategoryActionsSection
                
                // Recent Documents
                recentDocumentsSection
            }
            .padding()
        }
        .navigationTitle("Home")
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome")
                .font(.title)
                .fontWeight(.bold)
            Text("You have 12 documents")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Scan Button
    
    private var scanButtonSection: some View {
        Button(action: {
            // TODO: Open scanner
        }) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.system(size: 24))
                Text("Scan Document")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
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
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<5) { index in
                        recentDocumentCard(index: index)
                    }
                }
            }
        }
    }
    
    private func recentDocumentCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 120, height: 160)
                .cornerRadius(8)
            
            Text("Document \(index + 1)")
                .font(.caption)
                .lineLimit(1)
            Text("2 hours ago")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 120)
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
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
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
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        HomeViewOptionC()
    }
}
