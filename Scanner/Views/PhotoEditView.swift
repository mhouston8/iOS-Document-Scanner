//
//  PhotoEditView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct PhotoEditView: View {
    let images: [UIImage]  // Original images (for reset)
    @Binding var editedImages: [UIImage]?  // Edited images array
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentImages: [UIImage]  // Working copy of images
    @State private var currentPageIndex: Int = 0
    @State private var showingToolView: EditTool? = nil
    
    // Convenience initializer for single image (backward compatibility)
    init(image: UIImage, editedImage: Binding<UIImage?>) {
        self.images = [image]
        self._editedImages = Binding(
            get: { editedImage.wrappedValue.map { [$0] } },
            set: { editedImage.wrappedValue = $0?.first }
        )
        _currentImages = State(initialValue: [image])
    }
    
    // Multi-page initializer
    init(images: [UIImage], editedImages: Binding<[UIImage]?>) {
        self.images = images
        self._editedImages = editedImages
        _currentImages = State(initialValue: images)
    }
    
    // Computed property for current page image
    private var currentImage: UIImage {
        guard currentPageIndex < currentImages.count else {
            return images.first ?? UIImage()
        }
        return currentImages[currentPageIndex]
    }
    
    enum EditTool: String, CaseIterable {
        case crop = "Crop"
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
                editedImages = currentImages
                dismiss()
            }
            .foregroundColor(.blue)
            .fontWeight(.semibold)
            .disabled(currentImages == images)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Image Preview
    
    private var imagePreview: some View {
        GeometryReader { geometry in
            // Show error if no images
            if images.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    Text("No images to edit")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Image(uiImage: currentImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.2))
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
            rotateLeft()
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
        let binding = Binding<UIImage?>(
            get: { currentImage },
            set: { newImage in
                if let newImage = newImage, currentPageIndex < currentImages.count {
                    currentImages[currentPageIndex] = newImage
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
    }
    
    // MARK: - Actions
    
    private func rotateLeft() {
        //withAnimation {
            if currentPageIndex < currentImages.count {
                currentImages[currentPageIndex] = rotateImage(currentImages[currentPageIndex], by: -90)
          //  }
        }
    }
    
    private func rotateImage(_ image: UIImage, by degrees: CGFloat) -> UIImage {
        let radians = degrees * .pi / 180
        let rotatedSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context.rotate(by: radians)
        context.scaleBy(x: 1.0, y: -1.0)
        
        context.draw(image.cgImage!, in: CGRect(
            x: -image.size.width / 2,
            y: -image.size.height / 2,
            width: image.size.width,
            height: image.size.height
        ))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    private func applyAutoEnhance() {
        // TODO: Apply auto enhance to current page
        // For now, just update the current page
        withAnimation {
            if currentPageIndex < images.count && currentPageIndex < currentImages.count {
                currentImages[currentPageIndex] = images[currentPageIndex] // Placeholder - reset to original
            }
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
