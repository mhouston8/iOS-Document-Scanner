//
//  AnnotateView.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import PencilKit

struct AnnotateView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var canvasView = PKCanvasView()
    @State private var canvasSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                // Canvas with Image
                canvasWithImage
            }
        }
        .onAppear {
            setupToolPicker()
        }
        .onDisappear {
            cleanupToolPicker()
        }
    }
    
    private func setupToolPicker() {
        // Get the current window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        // Get or create the tool picker for the current window
        guard let toolPicker = PKToolPicker.shared(for: window) else {
            return
        }
        
        toolPicker.addObserver(canvasView)
        
        // Make canvas first responder first, then show tool picker
        DispatchQueue.main.async {
            self.canvasView.becomeFirstResponder()
            toolPicker.setVisible(true, forFirstResponder: self.canvasView)
        }
    }
    
    private func cleanupToolPicker() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        guard let toolPicker = PKToolPicker.shared(for: window) else {
            return
        }
        
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        toolPicker.removeObserver(canvasView)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.white)
            
            Spacer()
            
            Text("Annotate")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Apply") {
                applyAnnotation()
            }
            .foregroundColor(.blue)
            .fontWeight(.semibold)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Canvas
    
    private var canvasWithImage: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black) // Black background for image
                
                // Transparent canvas overlay for drawing
                PKCanvasViewWrapper(
                    canvasView: $canvasView
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear) // Ensure canvas is transparent
                .onAppear {
                    // Store the canvas display size for proper scaling when compositing
                    canvasSize = geometry.size
                }
                .onChange(of: geometry.size) { oldValue, newValue in
                    canvasSize = newValue
                }
            }
        }
    }
    
    
    private func applyAnnotation() {
        // Get the drawing from the canvas
        let drawing = canvasView.drawing
        
        // Calculate the actual displayed image size (maintaining aspect ratio)
        let imageAspectRatio = image.size.width / image.size.height
        var displayedImageSize: CGSize
        
        if canvasSize.width / canvasSize.height > imageAspectRatio {
            // Canvas is wider - image height fills canvas height
            displayedImageSize = CGSize(
                width: canvasSize.height * imageAspectRatio,
                height: canvasSize.height
            )
        } else {
            // Canvas is taller - image width fills canvas width
            displayedImageSize = CGSize(
                width: canvasSize.width,
                height: canvasSize.width / imageAspectRatio
            )
        }
        
        // Calculate the scale factor from displayed size to actual image size
        let scaleX = image.size.width / displayedImageSize.width
        let scaleY = image.size.height / displayedImageSize.height
        
        // Create a renderer for compositing
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let annotatedImage = renderer.image { context in
            // Draw the original image as the base
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            // Scale and translate the drawing to match the image coordinates
            context.cgContext.saveGState()
            
            // Calculate offset to center the image in the canvas
            let offsetX = (canvasSize.width - displayedImageSize.width) / 2
            let offsetY = (canvasSize.height - displayedImageSize.height) / 2
            
            // Transform: translate to account for centering, then scale to image size
            context.cgContext.translateBy(x: -offsetX * scaleX, y: -offsetY * scaleY)
            context.cgContext.scaleBy(x: scaleX, y: scaleY)
            
            // Draw the PencilKit drawing
            let drawingImage = drawing.image(from: CGRect(origin: .zero, size: canvasSize), scale: 1.0)
            drawingImage.draw(at: .zero)
            
            context.cgContext.restoreGState()
        }
        
        editedImage = annotatedImage
        dismiss()
    }
}

#Preview {
    AnnotateView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
