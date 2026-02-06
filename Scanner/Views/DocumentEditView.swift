//
//  PhotoEditView.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct DocumentEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: DocumentEditViewModel
    @State private var showingToolView: EditTool? = nil
    
    init(document: Document) {
        let databaseService = DatabaseService(client: SupabaseDatabaseClient())
        _viewModel = StateObject(wrappedValue: DocumentEditViewModel(
            document: document,
            databaseService: databaseService
        ))
    }
    
    enum EditTool: String, CaseIterable, Identifiable {
        case crop = "Crop"
        case filters = "Filters"
        case adjust = "Adjust"
        case sign = "Sign"
        case watermark = "Watermark"
        case annotate = "Annotate"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .crop: return "crop"
            case .filters: return "camera.filters"
            case .adjust: return "slider.horizontal.3"
            case .sign: return "signature"
            case .watermark: return "textformat"
            case .annotate: return "text.bubble"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            } else if viewModel.images.isEmpty {
                VStack {
                    Text("No images found")
                        .foregroundColor(.primary)
                }
            } else {
                VStack(spacing: 0) {
                    // Top Bar
                    topBar
                    
                    // Image Preview
                    imagePreview
                    
                    // Bottom Toolbar
                    bottomToolbar
                }
            }
        }
        .onAppear {
            if viewModel.pages.isEmpty {
                viewModel.loadPages()
            }
        }
        .sheet(item: Binding(
            get: { showingToolView != .crop ? showingToolView : nil },
            set: { newTool in showingToolView = newTool }
        )) { tool in
            NavigationStack {
                toolView(for: tool)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { showingToolView == .crop },
            set: { isPresented in
                if !isPresented {
                    showingToolView = nil
                }
            }
        )) {
            if let currentImage = viewModel.currentImage {
                let binding = Binding<UIImage?>(
                    get: { viewModel.currentImage },
                    set: { newImage in
                        if let newImage = newImage {
                            viewModel.updateCurrentImage(newImage)
                        }
                        showingToolView = nil
                    }
                )
                CropView(image: currentImage, editedImage: binding)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.primary)
            
            Spacer()
            
            Text("Edit Document")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("Done") {
                if viewModel.hasUnsavedChanges {
                    Task {
                        await viewModel.saveChanges()
                        dismiss()
                    }
                } else {
                    dismiss()
                }
            }
            .foregroundColor(viewModel.hasUnsavedChanges ? .blue : .gray)
            .fontWeight(.semibold)
            .disabled(!viewModel.hasUnsavedChanges || viewModel.isSaving)
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.95))
    }
    
    // MARK: - Image Preview
    
    private var imagePreview: some View {
        ZStack {
            if viewModel.editedImages.isEmpty {
                Color(.systemGray6)
            } else {
                TabView(selection: $viewModel.currentPageIndex) {
                    ForEach(0..<viewModel.editedImages.count, id: \.self) { index in
                        Image(uiImage: viewModel.editedImages[index])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
            // Custom page indicator for multi-page documents
            if viewModel.images.count > 1 {
                VStack {
                    HStack {
                        Spacer()
                        Text("\(viewModel.currentPageIndex + 1) / \(viewModel.images.count)")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray5).opacity(0.9))
                            .cornerRadius(8)
                            .padding()
                    }
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(EditTool.allCases, id: \.self) { tool in
                    toolButton(tool: tool)
                    
                    // Add rotate button after crop
                    if tool == .crop {
                        rotateButton
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground).opacity(0.95))
    }
    
    private var rotateButton: some View {
        Button(action: {
            viewModel.rotateCurrentImage(by: -90)
        }) {
            VStack(spacing: 8) {
                Image(systemName: "rotate.left")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color(.systemGray5))
                    )
                
                Text("Rotate")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private func toolButton(tool: EditTool) -> some View {
        Button(action: {
            showingToolView = tool
        }) {
            VStack(spacing: 8) {
                Image(systemName: tool.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color(.systemGray5))
                    )
                
                Text(tool.rawValue)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Tool Views
    
    @ViewBuilder
    private func toolView(for tool: EditTool) -> some View {
        if let currentImage = viewModel.currentImage {
            let binding = Binding<UIImage?>(
                get: { viewModel.currentImage },
                set: { newImage in
                    if let newImage = newImage {
                        viewModel.updateCurrentImage(newImage)
                    }
                    showingToolView = nil
                }
            )
            
            switch tool {
            case .crop:
                CropView(image: currentImage, editedImage: binding)
            case .filters:
                FiltersView(image: currentImage, editedImage: binding)
            case .adjust:
                AdjustView(image: currentImage, editedImage: binding)
            case .sign:
                SignView(image: currentImage, editedImage: binding)
            case .watermark:
                WatermarkView(image: currentImage, editedImage: binding)
            case .annotate:
                AnnotateView(image: currentImage, editedImage: binding)
            }
        } else {
            EmptyView()
        }
    }
    
}

#Preview {
    let document = Document(
        userId: UUID(),
        name: "Preview Document",
        pageCount: 1
    )
    return DocumentEditView(document: document)
}
