//
//  WatermarkView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import Foundation

struct WatermarkView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var watermarkText: String = ""
    @State private var watermarkOpacity: Double = 0.3
    @State private var watermarkSize: Double = 0.5
    @State private var watermarkAngle: Double = -45 // Degrees, negative for diagonal slant
    @State private var watermarkSpacing: Double = 200 // Spacing between repetitions
    @State private var previewImage: UIImage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                // Image Preview with Watermark
                imagePreviewWithWatermark
                
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
            
            Text("Watermark")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Apply") {
                applyWatermark()
            }
            .foregroundColor(.blue)
            .fontWeight(.semibold)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Image Preview
    
    private var imagePreviewWithWatermark: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Pattern watermark overlay
                if !watermarkText.isEmpty, let preview = previewImage {
                    Image(uiImage: preview)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                updatePreview(size: geometry.size)
            }
            .onChange(of: watermarkText) { oldValue, newValue in
                updatePreview(size: geometry.size)
            }
            .onChange(of: watermarkOpacity) { oldValue, newValue in
                updatePreview(size: geometry.size)
            }
            .onChange(of: watermarkSize) { oldValue, newValue in
                updatePreview(size: geometry.size)
            }
            .onChange(of: watermarkAngle) { oldValue, newValue in
                updatePreview(size: geometry.size)
            }
            .onChange(of: watermarkSpacing) { oldValue, newValue in
                updatePreview(size: geometry.size)
            }
            .onChange(of: geometry.size) { oldValue, newValue in
                updatePreview(size: newValue)
            }
        }
    }
    
    private func updatePreview(size: CGSize) {
        guard !watermarkText.isEmpty, size.width > 0, size.height > 0 else {
            previewImage = nil
            return
        }
        
        // Calculate displayed image size (maintaining aspect ratio)
        let imageAspectRatio = image.size.width / image.size.height
        var displayedImageSize: CGSize
        
        if size.width / size.height > imageAspectRatio {
            displayedImageSize = CGSize(width: size.height * imageAspectRatio, height: size.height)
        } else {
            displayedImageSize = CGSize(width: size.width, height: size.width / imageAspectRatio)
        }
        
        // Create pattern watermark image
        previewImage = createPatternWatermark(size: displayedImageSize)
    }
    
    private func createPatternWatermark(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Calculate font size
            let fontSize = CGFloat(watermarkSize * 40)
            let spacing = CGFloat(watermarkSpacing)
            let angleRadians = watermarkAngle * .pi / 180
            
            // Create text attributes
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(watermarkOpacity)
            ]
            
            // Calculate text size
            let textSize = (watermarkText as NSString).size(withAttributes: attributes)
            
            // Calculate how many repetitions we need to cover the entire image
            // We need enough to cover the diagonal when rotated
            let diagonal = sqrt(size.width * size.width + size.height * size.height)
            let repetitions = Int(diagonal / spacing) + 4
            
            // Draw repeating pattern in a grid
            // Create a grid pattern, then rotate each position
            for i in -repetitions...repetitions {
                for j in -repetitions...repetitions {
                    // Base position in unrotated grid (centered at origin)
                    let baseX = CGFloat(i) * spacing
                    let baseY = CGFloat(j) * spacing
                    
                    // Rotate this position around the center
                    let rotatedX = baseX * Foundation.cos(angleRadians) - baseY * Foundation.sin(angleRadians)
                    let rotatedY = baseX * Foundation.sin(angleRadians) + baseY * Foundation.cos(angleRadians)
                    
                    // Translate to center of image
                    let x = rotatedX + size.width / 2
                    let y = rotatedY + size.height / 2
                    
                    // Draw if within bounds (with margin for rotated text)
                    if x > -textSize.width * 2 && x < size.width + textSize.width * 2 &&
                       y > -textSize.height * 2 && y < size.height + textSize.height * 2 {
                        context.cgContext.saveGState()
                        context.cgContext.translateBy(x: x, y: y)
                        context.cgContext.rotate(by: angleRadians)
                        
                        let attributedString = NSAttributedString(string: watermarkText, attributes: attributes)
                        attributedString.draw(at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2))
                        
                        context.cgContext.restoreGState()
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 0) {
            // Compact Text Input
            HStack(spacing: 12) {
                Text("Text:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 50, alignment: .leading)
                
                TextField("Enter watermark text", text: $watermarkText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Compact Controls - Two columns
            HStack(spacing: 16) {
                // Left column
                VStack(spacing: 12) {
                    // Angle
                    VStack(spacing: 6) {
                        HStack {
                            Text("Angle")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text("\(Int(watermarkAngle))°")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Slider(value: $watermarkAngle, in: -90...90)
                            .tint(.cyan)
                    }
                    
                    // Opacity
                    VStack(spacing: 6) {
                        HStack {
                            Text("Opacity")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text("\(Int(watermarkOpacity * 100))%")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Slider(value: $watermarkOpacity, in: 0...1)
                            .tint(.cyan)
                    }
                }
                
                // Right column
                VStack(spacing: 12) {
                    // Size
                    VStack(spacing: 6) {
                        HStack {
                            Text("Size")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text("\(Int(watermarkSize * 100))%")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Slider(value: $watermarkSize, in: 0.1...1)
                            .tint(.cyan)
                    }
                    
                    // Spacing
                    VStack(spacing: 6) {
                        HStack {
                            Text("Spacing")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text("\(Int(watermarkSpacing))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Slider(value: $watermarkSpacing, in: 100...400)
                            .tint(.cyan)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.black.opacity(0.8))
    }
    
    
    // MARK: - Actions
    
    private func applyWatermark() {
        // TODO: Composite watermark onto image
        editedImage = image
        dismiss()
    }
}

#Preview {
    WatermarkView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
