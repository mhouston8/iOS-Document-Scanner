//
//  PKCanvasViewWrapper.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import PencilKit

struct PKCanvasViewWrapper: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var drawingPolicy: PKCanvasViewDrawingPolicy = .anyInput
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = drawingPolicy
        canvasView.backgroundColor = .clear // Make canvas transparent so image shows through
        canvasView.isOpaque = false // Allow transparency
        // Enable user interaction for drawing
        canvasView.isUserInteractionEnabled = true
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.backgroundColor = .clear // Ensure background stays clear
        uiView.isOpaque = false
        uiView.drawingPolicy = drawingPolicy
        uiView.isUserInteractionEnabled = true
    }
}
