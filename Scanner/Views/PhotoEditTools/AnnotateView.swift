//
//  AnnotateView.swift
//  Scanner
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
            }
        }
    }
    
    
    private func applyAnnotation() {
        // TODO: Composite annotations onto image
        editedImage = image
        dismiss()
    }
}

#Preview {
    AnnotateView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
