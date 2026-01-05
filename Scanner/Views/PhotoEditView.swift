//
//  PhotoEditView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct PhotoEditView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentImage: UIImage
    @State private var showingToolView: EditTool? = nil
    
    enum EditTool: String, CaseIterable {
        case crop = "Crop"
        case rotate = "Rotate"
        case filters = "Filters"
        case adjust = "Adjust"
        case removeBG = "Remove BG"
        case sign = "Sign"
        case watermark = "Watermark"
        case annotate = "Annotate"
        case redact = "Redact"
        case autoEnhance = "Auto"
        
        var icon: String {
            switch self {
            case .crop: return "crop"
            case .rotate: return "rotate.right"
            case .filters: return "camera.filters"
            case .adjust: return "slider.horizontal.3"
            case .removeBG: return "eye.slash"
            case .sign: return "signature"
            case .watermark: return "text.watermark"
            case .annotate: return "text.bubble"
            case .redact: return "eye.slash.fill"
            case .autoEnhance: return "sparkles"
            }
        }
    }
    
    init(image: UIImage, editedImage: Binding<UIImage?>) {
        self.image = image
        self._editedImage = editedImage
        _currentImage = State(initialValue: image)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                // Image Preview
                imagePreview
                
                // Bottom Toolbar
                bottomToolbar
            }
        }
        .fullScreenCover(item: Binding(
            get: { showingToolView.map { ToolWrapper(tool: $0) } },
            set: { showingToolView = $0?.tool }
        )) { wrapper in
            toolView(for: wrapper.tool)
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
                editedImage = currentImage
                dismiss()
            }
            .foregroundColor(.blue)
            .fontWeight(.semibold)
            .disabled(currentImage == image)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Image Preview
    
    private var imagePreview: some View {
        GeometryReader { geometry in
            Image(uiImage: currentImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.2))
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(EditTool.allCases, id: \.self) { tool in
                    toolButton(tool: tool)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.7))
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
        let binding = Binding<UIImage?>(
            get: { currentImage },
            set: { newImage in
                if let newImage = newImage {
                    currentImage = newImage
                }
                showingToolView = nil
            }
        )
        
        switch tool {
        case .crop:
            CropView(image: currentImage, editedImage: binding)
        case .rotate:
            RotateView(image: currentImage, editedImage: binding)
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
    }
    
    // MARK: - Actions
    
    private func applyAutoEnhance() {
        // TODO: Apply auto enhance
        // For now, just update the image
        withAnimation {
            currentImage = image // Placeholder
        }
    }
}

// Helper struct for fullScreenCover binding
struct ToolWrapper: Identifiable {
    let id = UUID()
    let tool: PhotoEditView.EditTool
}

#Preview {
    PhotoEditView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
