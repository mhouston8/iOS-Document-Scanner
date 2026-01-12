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
    
    var body: some View {
        CropViewControllerWrapper(
            image: image,
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

// MARK: - Mantis Crop View Controller Wrapper

struct CropViewControllerWrapper: UIViewControllerRepresentable {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> CropViewController {
        let cropViewController = Mantis.cropViewController(image: image)
        cropViewController.delegate = context.coordinator
        return cropViewController
    }
    
    func updateUIViewController(_ uiViewController: CropViewController, context: Context) {
        // No updates needed
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
