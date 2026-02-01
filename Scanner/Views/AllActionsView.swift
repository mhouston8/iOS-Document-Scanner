//
//  AllActionsView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

// All Actions View: Categorized Grid - All categories visible, organized sections
// This view shows all available actions organized by category
struct AllActionsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                // Header
                headerSection
                
                // Categorized Actions
                    scanAndImportSection
                    pdfToolsSection
                    editAndEnhanceSection
                    signAndMarkSection
                    organizeSection
                }
                .padding()
            }
            .navigationTitle("Document Tools")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("You have 12 documents")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Scan & Import Section
    
    private var scanAndImportSection: some View {
        categorySection(
            title: "Scan & Import",
            actions: [
                ActionItem(icon: "sparkles", title: "Smart Scan", color: .purple),
                ActionItem(icon: "photo", title: "Import Photos", color: .blue),
                ActionItem(icon: "folder", title: "Import Files", color: .green),
                ActionItem(icon: "person.text.rectangle", title: "Scan ID Card", color: .orange)
            ]
        )
    }
    
    // MARK: - PDF Tools Section
    
    private var pdfToolsSection: some View {
        categorySection(
            title: "PDF Tools",
            actions: [
                ActionItem(icon: "doc.on.doc", title: "Merge", color: .blue),
                ActionItem(icon: "doc.badge.plus", title: "Split PDF", color: .indigo),
                ActionItem(icon: "square.and.arrow.up", title: "Export PDF", color: .green),
                ActionItem(icon: "arrow.down.doc", title: "Compress", color: .gray)
            ]
        )
    }
    
    // MARK: - Edit & Enhance Section
    
    private var editAndEnhanceSection: some View {
        categorySection(
            title: "Edit & Enhance",
            actions: [
                ActionItem(icon: "pencil", title: "Edit", color: .blue),
                ActionItem(icon: "camera.filters", title: "Filters", color: .purple),
                ActionItem(icon: "sun.max", title: "Adjust", color: .yellow),
                ActionItem(icon: "eye.slash", title: "Remove BG", color: .red)
            ]
        )
    }
    
    // MARK: - Sign & Mark Section
    
    private var signAndMarkSection: some View {
        categorySection(
            title: "Sign & Mark",
            actions: [
                ActionItem(icon: "signature", title: "Sign", color: .blue),
                ActionItem(icon: "textformat", title: "Watermark", color: .cyan),
                ActionItem(icon: "text.bubble", title: "Annotate", color: .orange),
                ActionItem(icon: "eye.slash.fill", title: "Redact", color: .black)
            ]
        )
    }
    
    // MARK: - Organize Section
    
    private var organizeSection: some View {
        categorySection(
            title: "Organize",
            actions: [
                ActionItem(icon: "folder.badge.plus", title: "New Folder", color: .blue),
                ActionItem(icon: "tag", title: "Tags", color: .purple),
                ActionItem(icon: "star", title: "Favorites", color: .yellow),
                ActionItem(icon: "magnifyingglass", title: "Search", color: .gray)
            ]
        )
    }
    
    // MARK: - Category Section Helper
    
    private func categorySection(title: String, actions: [ActionItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
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
        }
    }
    
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
            .aspectRatio(1, contentMode: .fit) // Square aspect ratio
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Action Item Model

struct ActionItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
}

#Preview {
    NavigationStack {
        AllActionsView()
    }
}
