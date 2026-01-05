//
//  CropView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct CropView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAspectRatio: AspectRatio? = nil
    @State private var cropRect: CGRect = .zero
    
    enum AspectRatio: String, CaseIterable {
        case free = "Free"
        case square = "1:1"
        case fourThree = "4:3"
        case sixteenNine = "16:9"
        case threeFour = "3:4"
        
        var ratio: CGFloat? {
            switch self {
            case .free: return nil
            case .square: return 1.0
            case .fourThree: return 4.0 / 3.0
            case .sixteenNine: return 16.0 / 9.0
            case .threeFour: return 3.0 / 4.0
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                // Image Preview with Crop Overlay
                imagePreviewWithCrop
                
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
            
            Text("Crop")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Apply") {
                applyCrop()
            }
            .foregroundColor(.blue)
            .fontWeight(.semibold)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Image Preview
    
    private var imagePreviewWithCrop: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Crop overlay would go here
                // For now, just show the image
            }
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 0) {
            // Aspect Ratio Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AspectRatio.allCases, id: \.self) { ratio in
                        aspectRatioButton(ratio: ratio)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.black.opacity(0.7))
        }
    }
    
    private func aspectRatioButton(ratio: AspectRatio) -> some View {
        Button(action: {
            withAnimation {
                selectedAspectRatio = ratio
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: ratio == .free ? "crop" : "rectangle")
                    .font(.system(size: 24))
                    .foregroundColor(selectedAspectRatio == ratio ? .blue : .white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(selectedAspectRatio == ratio ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                    )
                
                Text(ratio.rawValue)
                    .font(.caption)
                    .foregroundColor(selectedAspectRatio == ratio ? .blue : .white)
            }
        }
    }
    
    // MARK: - Actions
    
    private func applyCrop() {
        // TODO: Apply crop to image
        // For now, just return the original image
        editedImage = image
        dismiss()
    }
}

#Preview {
    CropView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
