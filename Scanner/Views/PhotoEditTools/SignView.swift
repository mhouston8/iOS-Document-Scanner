//
//  SignView.swift
//  Axio Scan
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
    @State private var signatures: [Signature] = []
    @State private var selectedSignature: Signature?
    
    struct Signature: Identifiable {
        let id = UUID()
        var drawing: PKDrawing
        var position: CGPoint
        var size: CGSize
        
        init(drawing: PKDrawing, position: CGPoint = .zero, size: CGSize = CGSize(width: 200, height: 100)) {
            self.drawing = drawing
            self.position = position
            self.size = size
        }
    }
    
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
        GeometryReader { _ in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Display all signatures as draggable and resizable overlays
                ForEach(signatures) { signature in
                    SignatureOverlayView(
                        signature: signature,
                        isSelected: selectedSignature?.id == signature.id,
                        onDrag: { newPosition in
                            if let index = signatures.firstIndex(where: { $0.id == signature.id }) {
                                signatures[index].position = newPosition
                            }
                        },
                        onResize: { newSize in
                            if let index = signatures.firstIndex(where: { $0.id == signature.id }) {
                                signatures[index].size = newSize
                            }
                        },
                        onTap: {
                            selectedSignature = signature
                        }
                    )
                    .position(signature.position)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Deselect when tapping empty area
                selectedSignature = nil
            }
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Add Signature Button
            Button(action: {
                // Reset canvas for new signature
                canvasView.drawing = PKDrawing()
                showingSignaturePad = true
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "signature")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Signature")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Draw your signature")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.2),
                                    Color.cyan.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.4),
                                            Color.cyan.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .padding(.horizontal, 20)
            
            // Signature management buttons
            if !signatures.isEmpty {
                HStack(spacing: 12) {
                    // Delete selected signature
                    if selectedSignature != nil {
                        Button(action: {
                            if let selected = selectedSignature {
                                signatures.removeAll { $0.id == selected.id }
                                selectedSignature = nil
                            }
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.3))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Clear all signatures
                    Button(action: {
                        signatures.removeAll()
                        selectedSignature = nil
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Clear All")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.3))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.7))
        .sheet(isPresented: $showingSignaturePad) {
            SignaturePadView(
                canvasView: $canvasView,
                onDone: { drawing in
                    if !drawing.bounds.isEmpty {
                        // Add signature at center of screen initially
                        let newSignature = Signature(
                            drawing: drawing,
                            position: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2),
                            size: CGSize(width: 200, height: 100)
                        )
                        signatures.append(newSignature)
                        selectedSignature = newSignature
                    }
                    showingSignaturePad = false
                }
            )
        }
    }
    
    // MARK: - Actions
    
    private func applySignature() {
        guard !signatures.isEmpty else {
            editedImage = image
            dismiss()
            return
        }
        
        // Composite all signatures onto the image
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let signedImage = renderer.image { context in
            // Draw original image
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            // Draw each signature
            for signature in signatures {
                // Calculate signature position and size in image coordinates
                let imageAspectRatio = image.size.width / image.size.height
                let screenSize = UIScreen.main.bounds.size
                let screenAspectRatio = screenSize.width / screenSize.height
                
                // Calculate displayed image size (aspect fit)
                var displayedImageSize: CGSize
                if screenAspectRatio > imageAspectRatio {
                    displayedImageSize = CGSize(width: screenSize.height * imageAspectRatio, height: screenSize.height)
                } else {
                    displayedImageSize = CGSize(width: screenSize.width, height: screenSize.width / imageAspectRatio)
                }
                
                // Calculate scale factor from screen to image
                let scaleX = image.size.width / displayedImageSize.width
                let scaleY = image.size.height / displayedImageSize.height
                
                // Convert signature position from screen coordinates to image coordinates
                let imageX = (signature.position.x - (screenSize.width - displayedImageSize.width) / 2) * scaleX
                let imageY = (signature.position.y - (screenSize.height - displayedImageSize.height) / 2) * scaleY
                
                // Scale signature size
                let imageWidth = signature.size.width * scaleX
                let imageHeight = signature.size.height * scaleY
                
                // Draw signature
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: imageX, y: imageY)
                context.cgContext.scaleBy(x: scaleX, y: scaleY)
                
                // Render signature drawing (already in black on white, so render directly)
                let signatureImage = signature.drawing.image(from: signature.drawing.bounds, scale: 1.0)
                signatureImage.draw(in: CGRect(origin: .zero, size: signature.size))
                
                context.cgContext.restoreGState()
            }
        }
        
        editedImage = signedImage
        dismiss()
    }
}

// MARK: - Signature Pad View

struct SignaturePadView: View {
    @Binding var canvasView: PKCanvasView
    let onDone: (PKDrawing) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Instructions
                Text("Draw your signature")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                
                // Canvas with PKToolPicker
                PKCanvasViewWrapperWithToolPicker(canvasView: $canvasView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Sign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onDone(canvasView.drawing)
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - PKCanvasView Wrapper with Tool Picker

struct PKCanvasViewWrapperWithToolPicker: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        
        // Set default tool to black pen (visible on white background)
        let defaultTool = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.tool = defaultTool
        
        // Set up PKToolPicker - create new instance instead of using deprecated shared(for:)
        let toolPicker = PKToolPicker()
        
        // Set the tool picker's selected tool to black pen
        // Note: selectedTool is deprecated in iOS 18.0, but we set canvas tool directly which works
        canvasView.tool = defaultTool
        if #available(iOS 18.0, *) {
            // selectedToolItem is read-only, setting canvas tool directly is sufficient
        } else {
            toolPicker.selectedTool = defaultTool
        }
        
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        
        // Store tool picker in coordinator
        context.coordinator.toolPicker = toolPicker
        context.coordinator.defaultTool = defaultTool
        
        // Make canvas first responder to show tool picker
        DispatchQueue.main.async {
            canvasView.becomeFirstResponder()
            // Ensure tool is still set after becoming first responder
            canvasView.tool = defaultTool
            if #available(iOS 18.0, *) {
                // selectedToolItem is read-only, canvas tool is already set
            } else {
                toolPicker.selectedTool = defaultTool
            }
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Ensure tool is set correctly on update
        if let defaultTool = context.coordinator.defaultTool {
            uiView.tool = defaultTool
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var toolPicker: PKToolPicker?
        var defaultTool: PKTool?
    }
}

// MARK: - Signature Overlay View

struct SignatureOverlayView: View {
    let signature: SignView.Signature
    let isSelected: Bool
    let onDrag: (CGPoint) -> Void
    let onResize: (CGSize) -> Void
    let onTap: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var currentSize: CGSize
    @State private var resizeStartSize: CGSize = .zero
    @State private var resizeStartLocation: CGPoint = .zero
    
    init(signature: SignView.Signature, isSelected: Bool, onDrag: @escaping (CGPoint) -> Void, onResize: @escaping (CGSize) -> Void, onTap: @escaping () -> Void) {
        self.signature = signature
        self.isSelected = isSelected
        self.onDrag = onDrag
        self.onResize = onResize
        self.onTap = onTap
        _currentSize = State(initialValue: signature.size)
    }
    
    var body: some View {
        let signatureImage = signature.drawing.image(from: signature.drawing.bounds, scale: 1.0)
        let handleSize: CGFloat = 20
        let minSize: CGFloat = 50
        
        ZStack {
            Image(uiImage: signatureImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: currentSize.width, height: currentSize.height)
                .border(isSelected ? Color.blue : Color.clear, width: 2)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            let newPosition = CGPoint(
                                x: signature.position.x + value.translation.width,
                                y: signature.position.y + value.translation.height
                            )
                            onDrag(newPosition)
                            dragOffset = .zero
                        }
                )
                .onTapGesture {
                    onTap()
                }
            
            // Resize handles (only show when selected)
            if isSelected {
                // Bottom-right resize handle
                Circle()
                    .fill(Color.blue)
                    .frame(width: handleSize, height: handleSize)
                    .offset(
                        x: currentSize.width / 2 - handleSize / 2,
                        y: currentSize.height / 2 - handleSize / 2
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if resizeStartSize == .zero {
                                    resizeStartSize = currentSize
                                    resizeStartLocation = value.startLocation
                                }
                                
                                let deltaX = value.translation.width
                                let deltaY = value.translation.height
                                
                                let newWidth = max(minSize, resizeStartSize.width + deltaX * 2)
                                let newHeight = max(minSize, resizeStartSize.height + deltaY * 2)
                                
                                currentSize = CGSize(width: newWidth, height: newHeight)
                            }
                            .onEnded { _ in
                                onResize(currentSize)
                                resizeStartSize = .zero
                            }
                    )
            }
        }
        .onChange(of: signature.size) { oldValue, newValue in
            currentSize = newValue
        }
    }
}


#Preview {
    SignView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
