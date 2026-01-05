//
//  RotateView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct RotateView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var rotationAngle: Double = 0
    @State private var currentImage: UIImage
    
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
            
            Text("Rotate")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Apply") {
                applyRotation()
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
                .rotationEffect(.degrees(rotationAngle))
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Rotation Slider
            VStack(spacing: 12) {
                Text("\(Int(rotationAngle))°")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Slider(value: $rotationAngle, in: -180...180)
                    .tint(.blue)
                    .onChange(of: rotationAngle) { oldValue, newValue in
                        updatePreviewRotation(angle: newValue)
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Quick Rotation Buttons
            HStack(spacing: 20) {
                rotateButton(degrees: -90, icon: "rotate.left", label: "90° L")
                rotateButton(degrees: 90, icon: "rotate.right", label: "90° R")
                rotateButton(degrees: 180, icon: "arrow.2.circlepath", label: "180°")
                flipButton(horizontal: true, label: "Flip H")
                flipButton(horizontal: false, label: "Flip V")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Color.black.opacity(0.7))
    }
    
    private func rotateButton(degrees: CGFloat, icon: String, label: String) -> some View {
        Button(action: {
            withAnimation {
                rotationAngle = degrees
                updatePreviewRotation(angle: degrees)
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 70, height: 70)
            .background(Color.blue.opacity(0.3))
            .cornerRadius(12)
        }
    }
    
    private func flipButton(horizontal: Bool, label: String) -> some View {
        Button(action: {
            // TODO: Flip image
        }) {
            VStack(spacing: 8) {
                Image(systemName: horizontal ? "arrow.left.and.right" : "arrow.up.and.down")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 70, height: 70)
            .background(Color.green.opacity(0.3))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Actions
    
    private func updatePreviewRotation(angle: Double) {
        // Update preview image with rotation
        currentImage = rotateImage(image, by: angle)
    }
    
    private func applyRotation() {
        editedImage = currentImage
        dismiss()
    }
    
    private func rotateImage(_ image: UIImage, by degrees: Double) -> UIImage {
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
}

#Preview {
    RotateView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
