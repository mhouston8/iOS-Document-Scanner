//
//  DocumentToolsView.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

// Document Tools View: Categorized Grid - All categories visible, organized sections
// This view shows all available document tools organized by category
struct DocumentToolsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var selectedToolTitle: String?
    @State private var showingDocumentSelection = false
    @State private var showingScanner = false
    @State private var scannedPages: [UIImage] = []
    @State private var showingPhotoPicker = false
    @State private var selectedPhotos: [UIImage] = []
    @State private var showingFilePicker = false
    @State private var selectedFiles: [UIImage] = []
    @State private var showingMergeSelection = false
    @State private var showingSplitSelection = false
    @State private var showingNamingDialog = false
    @State private var documentName = ""
    
    private let databaseService: DatabaseService
    
    init() {
        self.databaseService = DatabaseService(client: SupabaseDatabaseClient())
    }
    
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
                    exportSection
                    organizeSection
                }
                .padding()
            }
            .navigationTitle("Document Tools")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showingDocumentSelection) {
                if let toolTitle = selectedToolTitle {
                    DocumentSelectionViaToolView(selectedToolTitle: toolTitle, authService: authService)
                        .environmentObject(authService)
                }
            }
            .navigationDestination(isPresented: $showingMergeSelection) {
                MergeDocumentSelectionView(authService: authService)
                    .environmentObject(authService)
            }
            .navigationDestination(isPresented: $showingSplitSelection) {
                SplitDocumentSelectionView(authService: authService)
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView(scannedPages: $scannedPages)
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(selectedImages: $selectedPhotos, selectionLimit: 0)
            }
            .sheet(isPresented: $showingFilePicker) {
                FilePickerView(selectedImages: $selectedFiles, allowsMultipleSelection: true)
            }
            .sheet(isPresented: $showingNamingDialog) {
                DocumentNamingView(
                    documentName: $documentName,
                    pageCount: getTotalPageCount(),
                    onSave: {
                        let imagesToSave = getImagesToSave()
                        saveDocument(name: documentName, images: imagesToSave)
                    },
                    onCancel: {
                        cancelDocumentNaming()
                    }
                )
            }
            .onChange(of: scannedPages) { oldValue, newValue in
                if !newValue.isEmpty {
                    handleScannedPages(newValue)
                }
            }
            .onChange(of: selectedPhotos) { oldValue, newValue in
                if !newValue.isEmpty {
                    handleSelectedPhotos(newValue)
                }
            }
            .onChange(of: selectedFiles) { oldValue, newValue in
                if !newValue.isEmpty {
                    handleSelectedFiles(newValue)
                }
            }
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
                ActionItem(icon: "folder", title: "Import Files", color: .green)
            ]
        )
    }
    
    // MARK: - PDF Tools Section
    
    private var pdfToolsSection: some View {
        categorySection(
            title: "PDF Tools",
            actions: [
                ActionItem(icon: "doc.on.doc", title: "Merge", color: .blue),
                ActionItem(icon: "doc.badge.plus", title: "Split", color: .indigo)
            ]
        )
    }
    
    // MARK: - Edit & Enhance Section
    
    private var editAndEnhanceSection: some View {
        categorySection(
            title: "Edit & Enhance",
            actions: [
                ActionItem(icon: "crop", title: "Crop", color: .green),
                ActionItem(icon: "rotate.left", title: "Rotate", color: .orange),
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
                ActionItem(icon: "text.bubble", title: "Annotate", color: .orange)
            ]
        )
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        categorySection(
            title: "Export",
            actions: [
                ActionItem(icon: "doc.fill", title: "Export to PDF", color: .red),
                ActionItem(icon: "photo", title: "Export to JPEG", color: .blue),
                ActionItem(icon: "photo.fill", title: "Export to PNG", color: .purple)
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
            .aspectRatio(1, contentMode: .fit) // Square aspect ratio
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Action Handling
    
    private func handleAction(_ action: ActionItem) {
        // Actions that require document selection
        let documentRequiredActions = [
            "Crop", "Rotate", "Filters", "Adjust", "Remove BG",
            "Sign", "Watermark", "Annotate",
            "Merge", "Split",
            "Export to PDF", "Export to JPEG", "Export to PNG"
        ]
        
        if documentRequiredActions.contains(action.title) {
            if action.title == "Merge" {
                showingMergeSelection = true
            } else if action.title == "Split PDF" {
                showingSplitSelection = true
            } else {
                selectedToolTitle = action.title
                showingDocumentSelection = true
            }
        } else if action.title == "Smart Scan" {
            showingScanner = true
        } else if action.title == "Import Photos" {
            showingPhotoPicker = true
        } else if action.title == "Import Files" {
            showingFilePicker = true
        } else {
            // Handle other actions that don't require documents (New Folder, etc.)
            // TODO: Implement these actions
            print("Action '\(action.title)' tapped - not yet implemented")
        }
    }
    
    // MARK: - Scanner Handling
    
    private func handleScannedPages(_ images: [UIImage]) {
        scannedPages = images
        documentName = generateDefaultDocumentName()
        showingNamingDialog = true
    }
    
    private func generateDefaultDocumentName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Document \(formatter.string(from: Date()))"
    }
    
    private func saveDocument(name: String, images: [UIImage]) {
        Task {
            do {
                // 1. Get current user ID
                guard let userId = await authService.currentUserId() else {
                    print("Error: No authenticated user")
                    return
                }
                
                // 2. Calculate file size (sum of JPEG data sizes)
                let fileSize = images.reduce(Int64(0)) { total, image in
                    let imageDataSize = image.jpegData(compressionQuality: 0.8)?.count ?? 0
                    return total + Int64(imageDataSize)
                }
                
                // 3. Create Document model
                let document = Document(
                    userId: userId,
                    name: name,
                    pageCount: images.count,
                    fileSize: fileSize
                )
                
                // 4. Save document and pages to database
                try await databaseService.createDocument(document, pages: images)
                
                print("Successfully saved document '\(name)' with \(images.count) pages")
                
                // 5. Clear state after successful save
                scannedPages = []
                selectedPhotos = []
                selectedFiles = []
                documentName = ""
                showingNamingDialog = false
            } catch {
                print("Error saving document: \(error)")
            }
        }
    }
    
    private func handleSelectedPhotos(_ images: [UIImage]) {
        selectedPhotos = images
        documentName = generateDefaultDocumentName()
        showingNamingDialog = true
    }
    
    private func handleSelectedFiles(_ images: [UIImage]) {
        selectedFiles = images
        documentName = generateDefaultDocumentName()
        showingNamingDialog = true
    }
    
    private func getTotalPageCount() -> Int {
        if !scannedPages.isEmpty {
            return scannedPages.count
        } else if !selectedPhotos.isEmpty {
            return selectedPhotos.count
        } else if !selectedFiles.isEmpty {
            return selectedFiles.count
        }
        return 0
    }
    
    private func getImagesToSave() -> [UIImage] {
        if !scannedPages.isEmpty {
            return scannedPages
        } else if !selectedPhotos.isEmpty {
            return selectedPhotos
        } else if !selectedFiles.isEmpty {
            return selectedFiles
        }
        return []
    }
    
    private func cancelDocumentNaming() {
        scannedPages = []
        selectedPhotos = []
        selectedFiles = []
        documentName = ""
        showingNamingDialog = false
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
        DocumentToolsView()
    }
}
