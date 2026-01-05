//
//  RedactView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import PencilKit

struct RedactView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var canvasView = PKCanvasView()
    @State private var redactionMode: RedactionMode = .blackBar
    
    enum RedactionMode: String, CaseIterable {
        case blackBar = "Black Bar"
        case blur = "Blur"
        case pixelate = "Pixelate"
        
        var icon: String {
            switch self {
            case .blackBar: return "rectangle.fill"
            case .blur: return "circle.lefthalf.filled"
            case .pixelate: return "square.grid.3x3"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                // Canvas with Image
                canvasWithImage
                
                // Bottom Toolbar
                bottomToolbar
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
            
            Text("Redact")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Apply") {
                applyRedaction()
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
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Redaction overlay canvas
                RedactionCanvasView(canvasView: $canvasView, mode: redactionMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            // Mode Selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(RedactionMode.allCases, id: \.self) { mode in
                        modeButton(mode: mode)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color.black.opacity(0.7))
            
            // Instructions
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.gray)
                Text("Draw over areas to redact")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.8))
        }
    }
    
    private func modeButton(mode: RedactionMode) -> some View {
        Button(action: {
            redactionMode = mode
        }) {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 22))
                    .foregroundColor(redactionMode == mode ? .red : .white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(redactionMode == mode ? Color.red.opacity(0.2) : Color.white.opacity(0.1))
                    )
                
                Text(mode.rawValue)
                    .font(.caption2)
                    .foregroundColor(redactionMode == mode ? .red : .white)
            }
        }
    }
    
    // MARK: - Actions
    
    private func applyRedaction() {
        // TODO: Apply redaction to image based on canvas drawing
        editedImage = image
        dismiss()
    }
}

// MARK: - Redaction Canvas View

struct RedactionCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let mode: RedactView.RedactionMode
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        
        switch mode {
        case .blackBar:
            canvasView.tool = PKInkingTool(.pen, color: .black, width: 20)
        case .blur:
            // Use a special blur tool (would need custom implementation)
            canvasView.tool = PKInkingTool(.pen, color: .clear, width: 20)
        case .pixelate:
            canvasView.tool = PKInkingTool(.pen, color: .gray, width: 20)
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        switch mode {
        case .blackBar:
            uiView.tool = PKInkingTool(.pen, color: .black, width: 20)
        case .blur:
            uiView.tool = PKInkingTool(.pen, color: .clear, width: 20)
        case .pixelate:
            uiView.tool = PKInkingTool(.pen, color: .gray, width: 20)
        }
    }
}

#Preview {
    RedactView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
