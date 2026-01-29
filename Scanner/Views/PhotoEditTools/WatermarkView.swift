//
//  WatermarkView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct WatermarkView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var watermarkText: String = ""
    @State private var watermarkPosition: WatermarkPosition = .bottomRight
    @State private var watermarkOpacity: Double = 0.5
    @State private var watermarkSize: Double = 0.5
    
    enum WatermarkPosition: String, CaseIterable {
        case topLeft = "Top Left"
        case topRight = "Top Right"
        case bottomLeft = "Bottom Left"
        case bottomRight = "Bottom Right"
        case center = "Center"
    }
    
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
                
                // Watermark overlay
                if !watermarkText.isEmpty {
                    Text(watermarkText)
                        .font(.system(size: CGFloat(watermarkSize * 30), weight: .semibold))
                        .foregroundColor(.white.opacity(watermarkOpacity))
                        .padding(8)
                        .background(Color.black.opacity(watermarkOpacity * 0.3))
                        .cornerRadius(4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignmentForPosition)
                }
            }
        }
    }
    
    private var alignmentForPosition: Alignment {
        switch watermarkPosition {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        case .center: return .center
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 0) {
            // Text Input
            VStack(spacing: 8) {
                TextField("Enter watermark text", text: $watermarkText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Position Grid
            VStack(spacing: 12) {
                Text("Position")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 3x2 Grid for positions
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        positionButton(.topLeft)
                        positionButton(.topRight)
                    }
                    HStack(spacing: 8) {
                        positionButton(.center)
                    }
                    HStack(spacing: 8) {
                        positionButton(.bottomLeft)
                        positionButton(.bottomRight)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Opacity and Size Controls
            VStack(spacing: 16) {
                // Opacity
                VStack(spacing: 8) {
                    HStack {
                        Text("Opacity")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(watermarkOpacity * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Slider(value: $watermarkOpacity, in: 0...1)
                        .tint(.cyan)
                }
                
                // Size
                VStack(spacing: 8) {
                    HStack {
                        Text("Size")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(watermarkSize * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Slider(value: $watermarkSize, in: 0.1...1)
                        .tint(.cyan)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.black.opacity(0.8))
    }
    
    private func positionButton(_ position: WatermarkPosition) -> some View {
        Button(action: {
            watermarkPosition = position
        }) {
            Text(position.rawValue)
                .font(.caption)
                .foregroundColor(watermarkPosition == position ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    watermarkPosition == position
                        ? Color.cyan
                        : Color.white.opacity(0.1)
                )
                .cornerRadius(8)
        }
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
