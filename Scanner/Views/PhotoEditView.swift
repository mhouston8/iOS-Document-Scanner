//
//  PhotoEditView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct PhotoEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: PhotoEditViewModel
    @State private var showingToolView: EditTool? = nil
    
    init(document: Document) {
        let databaseService = DatabaseService(client: SupabaseDatabaseClient())
        _viewModel = StateObject(wrappedValue: PhotoEditViewModel(
            document: document,
            databaseService: databaseService
        ))
    }
    
    enum EditTool: String, CaseIterable, Identifiable {
        case crop = "Crop"
        case filters = "Filters"
        case adjust = "Adjust"
        case removeBG = "Remove BG"
        case sign = "Sign"
        case watermark = "Watermark"
        case annotate = "Annotate"
        case redact = "Redact"
        case autoEnhance = "Auto"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .crop: return "crop"
            case .filters: return "camera.filters"
            case .adjust: return "slider.horizontal.3"
            case .removeBG: return "eye.slash"
            case .sign: return "signature"
            case .watermark: return "textformat"
            case .annotate: return "text.bubble"
            case .redact: return "eye.slash.fill"
            case .autoEnhance: return "sparkles"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if viewModel.images.isEmpty {
                VStack {
                    Text("No images found")
                        .foregroundColor(.white)
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
        .sheet(item: $showingToolView) { tool in
            NavigationStack {
                toolView(for: tool)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingToolView = nil
                            }
                        }
                    }
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
            .foregroundColor(.white)
            
            Spacer()
            
            Text("Edit Photo")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Done") {
                if viewModel.hasUnsavedChanges {
                    viewModel.saveChanges()
                }
                dismiss()
            }
            .foregroundColor(viewModel.hasUnsavedChanges ? .blue : .gray)
            .fontWeight(.semibold)
            .disabled(!viewModel.hasUnsavedChanges || viewModel.isSaving)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Image Preview
    
    private var imagePreview: some View {
        ZStack {
            if let currentImage = viewModel.currentImage {
                Image(uiImage: currentImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color.black
            }
            
            // Page indicator for multi-page documents
            if viewModel.images.count > 1 {
                VStack {
                    HStack {
                        Spacer()
                        Text("\(viewModel.currentPageIndex + 1) / \(viewModel.images.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
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
        .background(Color.black.opacity(0.7))
    }
    
    private var rotateButton: some View {
        Button(action: {
            viewModel.rotateCurrentImage(by: -90)
        }) {
            VStack(spacing: 8) {
                Image(systemName: "rotate.left")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
                
                Text("Rotate")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func toolButton(tool: EditTool) -> some View {
        Button(action: {
            if tool == .autoEnhance {
                applyAutoEnhance()
            } else {
                showingToolView = tool
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: tool.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
                
                Text(tool.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
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
            case .removeBG:
                RemoveBGView(image: currentImage, editedImage: binding)
            case .sign:
                SignView(image: currentImage, editedImage: binding)
            case .watermark:
                WatermarkView(image: currentImage, editedImage: binding)
            case .annotate:
                AnnotateView(image: currentImage, editedImage: binding)
            case .redact:
                RedactView(image: currentImage, editedImage: binding)
            case .autoEnhance:
                EmptyView()
            }
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Actions
    
    private func applyAutoEnhance() {
        // TODO: Implement auto enhance
    }
}

#Preview {
    let document = Document(
        userId: UUID(),
        name: "Preview Document",
        pageCount: 1
    )
    return PhotoEditView(document: document)
}
