//
//  RemoveBGView.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct RemoveBGView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var isProcessing = false
    @State private var processedImage: UIImage?
    
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
            
            Text("Remove Background")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Apply") {
                applyRemoveBG()
            }
            .foregroundColor(.blue)
            .fontWeight(.semibold)
            .disabled(processedImage == nil)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Image Preview
    
    private var imagePreview: some View {
        GeometryReader { geometry in
            Group {
                if let processed = processedImage {
                    Image(uiImage: processed)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 20) {
            if isProcessing {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                    Text("Removing background...")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding()
            } else {
                Button(action: {
                    processRemoveBG()
                }) {
                    HStack {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 20))
                        Text("Remove Background")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.3))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.7))
    }
    
    // MARK: - Actions
    
    private func processRemoveBG() {
        isProcessing = true
        
        // TODO: Implement background removal using Vision or ML model
        // For now, simulate processing
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            await MainActor.run {
                // Placeholder: return original image
                processedImage = image
                isProcessing = false
            }
        }
    }
    
    private func applyRemoveBG() {
        if let processed = processedImage {
            editedImage = processed
            dismiss()
        }
    }
}

#Preview {
    RemoveBGView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
