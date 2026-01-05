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
        ScrollView {
            VStack(spacing: 20) {
                // Text Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Watermark Text")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    TextField("Enter text", text: $watermarkText)
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
                
                // Position Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Position")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Picker("Position", selection: $watermarkPosition) {
                        ForEach(WatermarkPosition.allCases, id: \.self) { position in
                            Text(position.rawValue).tag(position)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 20)
                
                // Opacity Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Opacity")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(watermarkOpacity * 100))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Slider(value: $watermarkOpacity, in: 0...1)
                        .tint(.cyan)
                }
                .padding(.horizontal, 20)
                
                // Size Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Size")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(watermarkSize * 100))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Slider(value: $watermarkSize, in: 0.1...1)
                        .tint(.cyan)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
        }
        .background(Color.black.opacity(0.7))
        .frame(maxHeight: 300)
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
