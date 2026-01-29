//
//  FiltersView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct FiltersView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFilter: Filter? = nil
    @State private var filterIntensity: Double = 1.0
    @State private var currentImage: UIImage
    
    enum Filter: String, CaseIterable {
        case original = "Original"
        case blackWhite = "B&W"
        case vintage = "Vintage"
        case cool = "Cool"
        case warm = "Warm"
        case sepia = "Sepia"
        case dramatic = "Dramatic"
        case noir = "Noir"
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
                
                // Bottom Controls
                bottomControls
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
            
            Text("Filters")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Apply") {
                applyFilter()
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
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 0) {
            // Filter Intensity Slider (if filter selected)
            if selectedFilter != nil && selectedFilter != .original {
                VStack(spacing: 12) {
                    Text("Intensity")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Slider(value: $filterIntensity, in: 0...1)
                        .tint(.blue)
                        .onChange(of: filterIntensity) { oldValue, newValue in
                            applyFilterPreview()
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.8))
            }
            
            // Filter Selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Filter.allCases, id: \.self) { filter in
                        filterPreviewButton(filter: filter)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.black.opacity(0.7))
        }
    }
    
    private func filterPreviewButton(filter: Filter) -> some View {
        Button(action: {
            withAnimation {
                selectedFilter = filter
                filterIntensity = 1.0
                applyFilterPreview()
            }
        }) {
            VStack(spacing: 8) {
                // Filter preview thumbnail
                Image(uiImage: applyFilterToImage(image, filter: filter, intensity: 1.0))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 70)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedFilter == filter ? Color.blue : Color.clear, lineWidth: 3)
                    )
                
                Text(filter.rawValue)
                    .font(.caption)
                    .foregroundColor(selectedFilter == filter ? .blue : .white)
            }
        }
    }
    
    // MARK: - Actions
    
    private func applyFilterPreview() {
        guard let filter = selectedFilter else { return }
        currentImage = applyFilterToImage(image, filter: filter, intensity: filterIntensity)
    }
    
    private func applyFilterToImage(_ image: UIImage, filter: Filter, intensity: Double) -> UIImage {
        guard filter != .original else { return image }
        
        guard let ciImage = CIImage(image: image) else { return image }
        let context = CIContext()
        
        var filteredImage: CIImage?
        
        switch filter {
        case .original:
            return image
            
        case .blackWhite:
            let colorControls = CIFilter.colorControls()
            colorControls.inputImage = ciImage
            colorControls.saturation = 0.0
            filteredImage = colorControls.outputImage
            
        case .vintage:
            // Use CIPhotoEffectInstant filter
            if let filter = CIFilter(name: "CIPhotoEffectInstant") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filteredImage = filter.outputImage
            }
            
        case .cool:
            // Cool temperature: use color controls with slight brightness/contrast adjustment
            // and reduce saturation slightly to simulate cool tone
            let colorControls = CIFilter.colorControls()
            colorControls.inputImage = ciImage
            colorControls.brightness = 0.05
            colorControls.contrast = 1.1
            colorControls.saturation = 0.9
            filteredImage = colorControls.outputImage
            
        case .warm:
            // Warm temperature: use color controls with warm tone simulation
            let colorControls = CIFilter.colorControls()
            colorControls.inputImage = ciImage
            colorControls.brightness = 0.1
            colorControls.contrast = 1.05
            colorControls.saturation = 1.1
            filteredImage = colorControls.outputImage
            
        case .sepia:
            let sepiaFilter = CIFilter.sepiaTone()
            sepiaFilter.inputImage = ciImage
            sepiaFilter.intensity = Float(intensity)
            filteredImage = sepiaFilter.outputImage
            
        case .dramatic:
            // Use CIPhotoEffectDramatic filter
            if let filter = CIFilter(name: "CIPhotoEffectDramatic") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filteredImage = filter.outputImage
            }
            
        case .noir:
            // Use CIPhotoEffectNoir filter
            if let filter = CIFilter(name: "CIPhotoEffectNoir") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filteredImage = filter.outputImage
            }
        }
        
        guard var outputImage = filteredImage else { return image }
        
        // Apply intensity by blending filtered image with original (except for sepia which has built-in intensity)
        if intensity < 1.0 && filter != .sepia {
            // Render both images to CGImage for blending
            guard let filteredCG = context.createCGImage(outputImage, from: outputImage.extent),
                  let originalCG = context.createCGImage(ciImage, from: ciImage.extent) else {
                return image
            }
            
            // Blend using UIKit/Core Graphics
            let size = image.size
            let scale = image.scale
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            defer { UIGraphicsEndImageContext() }
            
            guard let ctx = UIGraphicsGetCurrentContext() else {
                return image
            }
            
            // Draw original image
            UIImage(cgImage: originalCG, scale: scale, orientation: image.imageOrientation)
                .draw(in: CGRect(origin: .zero, size: size))
            
            // Draw filtered image with opacity based on intensity
            ctx.setAlpha(CGFloat(intensity))
            UIImage(cgImage: filteredCG, scale: scale, orientation: image.imageOrientation)
                .draw(in: CGRect(origin: .zero, size: size))
            
            if let blendedImage = UIGraphicsGetImageFromCurrentImageContext() {
                return blendedImage
            }
        }
        
        let finalImage = outputImage
        
        // Render CIImage back to UIImage
        guard let cgImage = context.createCGImage(finalImage, from: finalImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func applyFilter() {
        editedImage = currentImage
        dismiss()
    }
}

#Preview {
    FiltersView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
