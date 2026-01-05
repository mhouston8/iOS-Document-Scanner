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
    @State private var selectedTool: EditTool? = nil
    
    enum EditTool: String, CaseIterable {
        case crop = "Crop"
        case rotate = "Rotate"
        case filters = "Filters"
        case adjust = "Adjust"
        case autoEnhance = "Auto"
        
        var icon: String {
            switch self {
            case .crop: return "crop"
            case .rotate: return "rotate.right"
            case .filters: return "camera.filters"
            case .adjust: return "slider.horizontal.3"
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
        VStack(spacing: 0) {
            // Tool Selection
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
            
            // Tool Options (when tool is selected)
            if let selectedTool = selectedTool {
                toolOptionsView(for: selectedTool)
            }
        }
    }
    
    private func toolButton(tool: EditTool) -> some View {
        Button(action: {
            withAnimation {
                if selectedTool == tool {
                    selectedTool = nil
                } else {
                    selectedTool = tool
                }
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: tool.icon)
                    .font(.system(size: 24))
                    .foregroundColor(selectedTool == tool ? .blue : .white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(selectedTool == tool ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                    )
                
                Text(tool.rawValue)
                    .font(.caption)
                    .foregroundColor(selectedTool == tool ? .blue : .white)
            }
        }
    }
    
    private func toolOptionsView(for tool: EditTool) -> some View {
        Group {
            switch tool {
            case .crop:
                cropOptionsView
            case .rotate:
                rotateOptionsView
            case .filters:
                filterOptionsView
            case .adjust:
                adjustOptionsView
            case .autoEnhance:
                autoEnhanceOptionsView
            }
        }
        .frame(height: 120)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Tool Options
    
    private var cropOptionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                cropAspectButton("Free", ratio: nil)
                cropAspectButton("1:1", ratio: 1.0)
                cropAspectButton("4:3", ratio: 4.0/3.0)
                cropAspectButton("16:9", ratio: 16.0/9.0)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func cropAspectButton(_ title: String, ratio: CGFloat?) -> some View {
        Button(action: {
            // TODO: Apply crop
        }) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(8)
        }
    }
    
    private var rotateOptionsView: some View {
        HStack(spacing: 20) {
            rotateButton(degrees: -90, icon: "rotate.left")
            rotateButton(degrees: 90, icon: "rotate.right")
            rotateButton(degrees: 180, icon: "arrow.2.circlepath")
        }
        .padding(.horizontal, 20)
    }
    
    private func rotateButton(degrees: CGFloat, icon: String) -> some View {
        Button(action: {
            // TODO: Rotate image
            currentImage = rotateImage(currentImage, by: degrees)
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                Text("\(Int(degrees))°")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
            .background(Color.blue.opacity(0.3))
            .cornerRadius(12)
        }
    }
    
    private var filterOptionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                filterButton("Original", filter: nil)
                filterButton("B&W", filter: "bw")
                filterButton("Vintage", filter: "vintage")
                filterButton("Cool", filter: "cool")
                filterButton("Warm", filter: "warm")
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func filterButton(_ title: String, filter: String?) -> some View {
        Button(action: {
            // TODO: Apply filter
        }) {
            VStack(spacing: 8) {
                // Preview thumbnail
                Image(uiImage: currentImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                            .opacity(0)
                    )
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var adjustOptionsView: some View {
        VStack(spacing: 12) {
            adjustSlider(title: "Brightness", value: 0.5)
            adjustSlider(title: "Contrast", value: 0.5)
        }
        .padding(.horizontal, 20)
    }
    
    private func adjustSlider(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
            Slider(value: .constant(value), in: 0...1)
                .tint(.blue)
        }
    }
    
    private var autoEnhanceOptionsView: some View {
        Button(action: {
            // TODO: Auto enhance
        }) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                Text("Auto Enhance")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.3))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Functions
    
    private func rotateImage(_ image: UIImage, by degrees: CGFloat) -> UIImage {
        let radians = degrees * .pi / 180
        let rotatedSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        UIGraphicsBeginImageContext(rotatedSize)
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
}

#Preview {
    PhotoEditView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
