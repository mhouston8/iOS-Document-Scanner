//
//  AdjustView.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct AdjustView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var brightness: Double = 0.5 // 0-1 maps to -1.0 to 1.0
    @State private var contrast: Double = 0.5 // 0-1 maps to 0.0 to 2.0
    @State private var saturation: Double = 0.5 // 0-1 maps to 0.0 to 2.0
    @State private var currentImage: UIImage
    @State private var showingBeforeAfter = false
    
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
        .onAppear {
            // Initialize preview with original image (no adjustments at default values)
            updatePreview()
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
            
            Button(action: {
                withAnimation {
                    showingBeforeAfter.toggle()
                }
            }) {
                Text(showingBeforeAfter ? "After" : "Before")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button("Apply") {
                applyAdjustments()
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
            Image(uiImage: showingBeforeAfter ? image : currentImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Brightness
                adjustmentSlider(
                    title: "Brightness",
                    icon: "sun.max",
                    value: $brightness
                )
                
                // Contrast
                adjustmentSlider(
                    title: "Contrast",
                    icon: "circle.lefthalf.filled",
                    value: $contrast
                )
                
                // Saturation
                adjustmentSlider(
                    title: "Saturation",
                    icon: "paintpalette",
                    value: $saturation
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.black.opacity(0.7))
        .frame(maxHeight: 300)
    }
    
    private func adjustmentSlider(title: String, icon: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                // Show percentage relative to center (0%)
                let percentage = Int((value.wrappedValue - 0.5) * 200)
                Text(percentage >= 0 ? "+\(percentage)%" : "\(percentage)%")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 50, alignment: .trailing)
            }
            
            Slider(value: value, in: 0...1)
                .tint(.blue)
                .onChange(of: value.wrappedValue) { oldValue, newValue in
                    updatePreview()
                }
        }
    }
    
    // MARK: - Actions
    
    private func updatePreview() {
        currentImage = applyAdjustmentsToImage(image)
    }
    
    private func applyAdjustmentsToImage(_ inputImage: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: inputImage) else {
            return inputImage
        }
        
        // Map slider values (0-1) to filter values
        // Brightness: 0 -> -1.0, 0.5 -> 0.0, 1.0 -> 1.0
        let brightnessValue = (brightness - 0.5) * 2.0
        
        // Contrast: 0 -> 0.0, 0.5 -> 1.0, 1.0 -> 2.0
        let contrastValue = contrast * 2.0
        
        // Saturation: 0 -> 0.0, 0.5 -> 1.0, 1.0 -> 2.0
        let saturationValue = saturation * 2.0
        
        // Apply CIColorControls filter
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.brightness = Float(brightnessValue)
        filter.contrast = Float(contrastValue)
        filter.saturation = Float(saturationValue)
        
        guard let outputImage = filter.outputImage else {
            return inputImage
        }
        
        // Render the filtered image
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return inputImage
        }
        
        return UIImage(cgImage: cgImage, scale: inputImage.scale, orientation: inputImage.imageOrientation)
    }
    
    private func applyAdjustments() {
        editedImage = currentImage
        dismiss()
    }
}

#Preview {
    AdjustView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
