//
//  AdjustView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct AdjustView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var brightness: Double = 0.5
    @State private var contrast: Double = 0.5
    @State private var saturation: Double = 0.5
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
                
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
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
        // TODO: Apply adjustments to image
        // For now, just update the current image
        currentImage = applyAdjustmentsToImage(image)
    }
    
    private func applyAdjustmentsToImage(_ image: UIImage) -> UIImage {
        // TODO: Apply brightness, contrast, saturation
        // For now, return original
        return image
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
