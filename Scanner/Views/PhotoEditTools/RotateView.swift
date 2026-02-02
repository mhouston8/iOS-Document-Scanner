//
//  RotateView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import UIKit

struct RotateView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentImage: UIImage
    @State private var rotationAngle: CGFloat = 0 // Total rotation in degrees
    @State private var showingBeforeAfter = false
    
    init(image: UIImage, editedImage: Binding<UIImage?>) {
        self.image = image
        self._editedImage = editedImage
        _currentImage = State(initialValue: image)
    }
    
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
            
            Button(action: {
                withAnimation {
                    showingBeforeAfter.toggle()
                }
            }) {
                Text(showingBeforeAfter ? "After" : "Before")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button("Apply") {
                applyRotation()
            }
            .foregroundColor(.blue)
            .fontWeight(.semibold)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Image Preview
    
    private var imagePreview: some View {
        GeometryReader { geometry in
            Image(uiImage: showingBeforeAfter ? image : currentImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Rotation Buttons
            HStack(spacing: 20) {
                // Rotate 90° Counter-Clockwise
                rotationButton(
                    icon: "rotate.left",
                    title: "90° Left",
                    action: {
                        rotateImage(by: -90)
                    }
                )
                
                // Rotate 180°
                rotationButton(
                    icon: "rotate.right",
                    title: "180°",
                    action: {
                        rotateImage(by: 180)
                    }
                )
                
                // Rotate 90° Clockwise
                rotationButton(
                    icon: "rotate.right",
                    title: "90° Right",
                    action: {
                        rotateImage(by: 90)
                    }
                )
            }
            .padding(.horizontal)
            
            // Flip Buttons
            HStack(spacing: 20) {
                // Flip Horizontal
                rotationButton(
                    icon: "arrow.left.and.right",
                    title: "Flip H",
                    action: {
                        flipImage(horizontal: true)
                    }
                )
                
                // Flip Vertical
                rotationButton(
                    icon: "arrow.up.and.down",
                    title: "Flip V",
                    action: {
                        flipImage(horizontal: false)
                    }
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .background(Color.black.opacity(0.7))
    }
    
    private func rotationButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation {
                action()
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray5).opacity(0.3))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Rotation Logic
    
    private func rotateImage(by degrees: CGFloat) {
        rotationAngle += degrees
        currentImage = rotateImage(currentImage, by: degrees)
    }
    
    private func flipImage(horizontal: Bool) {
        currentImage = flipImage(currentImage, horizontal: horizontal)
    }
    
    private func rotateImage(_ image: UIImage, by degrees: CGFloat) -> UIImage {
        let radians = degrees * .pi / 180
        let rotatedSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        
        // Move to center of rotated space
        context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context.rotate(by: radians)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // Draw image centered at origin
        context.draw(image.cgImage!, in: CGRect(
            x: -image.size.width / 2,
            y: -image.size.height / 2,
            width: image.size.width,
            height: image.size.height
        ))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    private func flipImage(_ image: UIImage, horizontal: Bool) -> UIImage {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        
        if horizontal {
            // Flip horizontally
            context.translateBy(x: size.width, y: 0)
            context.scaleBy(x: -1.0, y: 1.0)
        } else {
            // Flip vertically
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1.0, y: -1.0)
        }
        
        image.draw(in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    private func applyRotation() {
        editedImage = currentImage
        dismiss()
    }
}

#Preview {
    RotateView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
