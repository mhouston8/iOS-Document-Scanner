//
//  HomeViewOptionB.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

// Option B: Collapsible Sections - Categories can be expanded/collapsed
struct HomeViewOptionB: View {
    @State private var expandedSections: Set<String> = ["Scan & Import"] // Start with first section expanded
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Large Scan Button
                scanButtonSection
                
                // Collapsible Category Sections
                collapsibleSection(
                    title: "Scan & Import",
                    actions: [
                        ActionItem(icon: "sparkles", title: "Smart Scan", color: .purple),
                        ActionItem(icon: "photo", title: "Import Photos", color: .blue),
                        ActionItem(icon: "folder", title: "Import Files", color: .green),
                        ActionItem(icon: "person.text.rectangle", title: "Scan ID Card", color: .orange)
                    ]
                )
                
                collapsibleSection(
                    title: "PDF Tools",
                    actions: [
                        ActionItem(icon: "doc.on.doc", title: "Merge", color: .blue),
                        ActionItem(icon: "doc.badge.plus", title: "Split PDF", color: .indigo),
                        ActionItem(icon: "square.and.arrow.up", title: "Export PDF", color: .green),
                        ActionItem(icon: "arrow.down.doc", title: "Compress", color: .gray)
                    ]
                )
                
                collapsibleSection(
                    title: "Edit & Enhance",
                    actions: [
                        ActionItem(icon: "pencil", title: "Edit", color: .blue),
                        ActionItem(icon: "camera.filters", title: "Filters", color: .purple),
                        ActionItem(icon: "sun.max", title: "Adjust", color: .yellow),
                        ActionItem(icon: "eye.slash", title: "Remove BG", color: .red)
                    ]
                )
                
                collapsibleSection(
                    title: "Sign & Mark",
                    actions: [
                        ActionItem(icon: "signature", title: "Sign", color: .blue),
                        ActionItem(icon: "text.watermark", title: "Watermark", color: .cyan),
                        ActionItem(icon: "text.bubble", title: "Annotate", color: .orange),
                        ActionItem(icon: "eye.slash.fill", title: "Redact", color: .black)
                    ]
                )
                
                collapsibleSection(
                    title: "Organize",
                    actions: [
                        ActionItem(icon: "folder.badge.plus", title: "New Folder", color: .blue),
                        ActionItem(icon: "tag", title: "Tags", color: .purple),
                        ActionItem(icon: "star", title: "Favorites", color: .yellow),
                        ActionItem(icon: "magnifyingglass", title: "Search", color: .gray)
                    ]
                )
                
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
    
    // MARK: - Collapsible Section
    
    private func collapsibleSection(title: String, actions: [ActionItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation {
                    if expandedSections.contains(title) {
                        expandedSections.remove(title)
                    } else {
                        expandedSections.insert(title)
                    }
                }
            }) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Image(systemName: expandedSections.contains(title) ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if expandedSections.contains(title) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(actions) { action in
                        actionButton(action: action)
                    }
                }
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        HomeViewOptionB()
    }
}
