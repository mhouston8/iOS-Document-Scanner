//
//  SignView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import PencilKit

struct SignView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var canvasView = PKCanvasView()
    @State private var showingSignaturePad = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                // Image Preview with Signature Overlay
                imagePreviewWithSignature
                
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
            
            Text("Sign")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Apply") {
                applySignature()
            }
            .foregroundColor(.blue)
            .fontWeight(.semibold)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Image Preview
    
    private var imagePreviewWithSignature: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Signature overlay would go here
                // For now, show placeholder
            }
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 20) {
            Button(action: {
                showingSignaturePad = true
            }) {
                HStack {
                    Image(systemName: "signature")
                        .font(.system(size: 20))
                    Text("Add Signature")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.3))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            // Signature options
            HStack(spacing: 16) {
                Button("Clear") {
                    canvasView.drawing = PKDrawing()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.3))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.7))
        .sheet(isPresented: $showingSignaturePad) {
            SignaturePadView(canvasView: $canvasView, tool: PKInkingTool(.pen, color: .black, width: 3))
        }
    }
    
    // MARK: - Actions
    
    private func applySignature() {
        // TODO: Composite signature onto image
        editedImage = image
        dismiss()
    }
}

// MARK: - Signature Pad View

struct SignaturePadView: View {
    @Binding var canvasView: PKCanvasView
    let tool: PKTool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                PKCanvasViewWrapper(canvasView: $canvasView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Sign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}


#Preview {
    SignView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
