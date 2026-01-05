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
    @State private var selectedTool: AnnotationTool = .pen
    @State private var penColor: Color = .black
    @State private var penWidth: Double = 3
    
    enum AnnotationTool: String, CaseIterable {
        case pen = "Pen"
        case marker = "Marker"
        case highlighter = "Highlighter"
        case eraser = "Eraser"
        
        var icon: String {
            switch self {
            case .pen: return "pencil"
            case .marker: return "pencil.tip"
            case .highlighter: return "highlighter"
            case .eraser: return "eraser"
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
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                PKCanvasViewWrapper(
                    canvasView: $canvasView,
                    tool: toolForAnnotation(selectedTool, color: penColor, width: penWidth)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            // Tool Selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AnnotationTool.allCases, id: \.self) { tool in
                        toolButton(tool: tool)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color.black.opacity(0.7))
            
            // Color and Width Controls (if not eraser)
            if selectedTool != .eraser {
                HStack(spacing: 20) {
                    // Color Picker
                    colorPicker
                    
                    // Width Slider
                    widthSlider
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.8))
            }
        }
    }
    
    private func toolButton(tool: AnnotationTool) -> some View {
        Button(action: {
            selectedTool = tool
        }) {
            VStack(spacing: 6) {
                Image(systemName: tool.icon)
                    .font(.system(size: 22))
                    .foregroundColor(selectedTool == tool ? .blue : .white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(selectedTool == tool ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                    )
                
                Text(tool.rawValue)
                    .font(.caption2)
                    .foregroundColor(selectedTool == tool ? .blue : .white)
            }
        }
    }
    
    private var colorPicker: some View {
        HStack(spacing: 12) {
            Text("Color")
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)
            
            HStack(spacing: 12) {
                ForEach([Color.black, Color.red, Color.blue, Color.green, Color.yellow], id: \.self) { color in
                    Button(action: {
                        penColor = color
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(penColor == color ? Color.white : Color.clear, lineWidth: 2)
                            )
                    }
                }
            }
        }
    }
    
    private var widthSlider: some View {
        HStack(spacing: 12) {
            Text("Width")
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)
            
            Slider(value: $penWidth, in: 1...10)
                .tint(.orange)
        }
    }
    
    // MARK: - Actions
    
    private func toolForAnnotation(_ tool: AnnotationTool, color: Color, width: Double) -> PKTool {
        switch tool {
        case .pen:
            return PKInkingTool(.pen, color: UIColor(color), width: CGFloat(width))
        case .marker:
            return PKInkingTool(.marker, color: UIColor(color), width: CGFloat(width * 2))
        case .highlighter:
            return PKInkingTool(.marker, color: UIColor(color).withAlphaComponent(0.5), width: CGFloat(width * 3))
        case .eraser:
            return PKEraserTool(.vector)
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
