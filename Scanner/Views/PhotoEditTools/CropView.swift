//
//  CropView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import Mantis

struct CropView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var cropViewController: CropViewController?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                // Crop View Controller
                CropViewControllerWrapper(
                    image: image,
                    cropViewController: $cropViewController,
                    onCrop: { croppedImage in
                        editedImage = croppedImage
                        dismiss()
                    },
                    onCancel: {
                        dismiss()
                    }
                )
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
            
            Text("Crop")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Apply") {
                cropViewController?.crop()
            }
            .foregroundColor(.blue)
            .fontWeight(.semibold)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
}

// MARK: - Mantis Crop View Controller Wrapper

struct CropViewControllerWrapper: UIViewControllerRepresentable {
    let image: UIImage
    @Binding var cropViewController: CropViewController?
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> CropViewController {
        let cropViewController = Mantis.cropViewController(image: image)
        cropViewController.delegate = context.coordinator
        
        // Store reference for Apply button
        DispatchQueue.main.async {
            self.cropViewController = cropViewController
        }
        
        return cropViewController
    }
    
    func updateUIViewController(_ uiViewController: CropViewController, context: Context) {
        // Update reference if needed
        if cropViewController != uiViewController {
            DispatchQueue.main.async {
                self.cropViewController = uiViewController
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCrop: onCrop, onCancel: onCancel)
    }
    
    class Coordinator: NSObject, CropViewControllerDelegate {
        let onCrop: (UIImage) -> Void
        let onCancel: () -> Void
        
        init(onCrop: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onCrop = onCrop
            self.onCancel = onCancel
        }
        
        func cropViewControllerDidCrop(_ cropViewController: Mantis.CropViewController, cropped: UIImage, transformation: Mantis.Transformation, cropInfo: Mantis.CropInfo) {
            onCrop(cropped)
        }
        
        func cropViewControllerDidCancel(_ cropViewController: Mantis.CropViewController, original: UIImage) {
            onCancel()
        }
        
        func cropViewControllerDidFailToCrop(_ cropViewController: Mantis.CropViewController, original: UIImage) {
            // Handle crop failure - just cancel
            onCancel()
        }
        
        func cropViewControllerDidBeginResize(_ cropViewController: Mantis.CropViewController) {
            // Optional: Handle resize begin if needed
        }
        
        func cropViewControllerDidEndResize(_ cropViewController: Mantis.CropViewController, original: UIImage, cropInfo: Mantis.CropInfo) {
            // Optional: Handle resize end if needed
        }
    }
}

#Preview {
    CropView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
