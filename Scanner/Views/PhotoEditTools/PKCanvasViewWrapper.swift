//
//  PKCanvasViewWrapper.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import PencilKit

struct PKCanvasViewWrapper: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var tool: PKTool? = nil
    var drawingPolicy: PKCanvasViewDrawingPolicy = .anyInput
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = drawingPolicy
        if let tool = tool {
            canvasView.tool = tool
        }
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if let tool = tool {
            uiView.tool = tool
        }
    }
}
