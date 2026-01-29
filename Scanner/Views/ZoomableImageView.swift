//
//  ZoomableImageView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI
import UIKit

struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .black
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView
        context.coordinator.scrollView = scrollView
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let imageView = context.coordinator.imageView else { return }
        
        // Update image if it changed
        if imageView.image !== image {
            imageView.image = image
            
            // Reset zoom when image changes
            scrollView.zoomScale = 1.0
            scrollView.contentOffset = .zero
        }
        
        // Update image view frame to fit within scroll view bounds
        let boundsSize = scrollView.bounds.size
        guard boundsSize.width > 0 && boundsSize.height > 0 else { return }
        
        let imageSize = image.size
        guard imageSize.width > 0 && imageSize.height > 0 else { return }
        
        // Calculate aspect fit size
        let imageAspectRatio = imageSize.width / imageSize.height
        let boundsAspectRatio = boundsSize.width / boundsSize.height
        
        var frameSize: CGSize
        if imageAspectRatio > boundsAspectRatio {
            // Image is wider - fit to width
            frameSize = CGSize(width: boundsSize.width, height: boundsSize.width / imageAspectRatio)
        } else {
            // Image is taller - fit to height
            frameSize = CGSize(width: boundsSize.height * imageAspectRatio, height: boundsSize.height)
        }
        
        imageView.frame = CGRect(origin: .zero, size: frameSize)
        scrollView.contentSize = frameSize
        
        // Center the image using content inset
        let xOffset = max(0, (boundsSize.width - frameSize.width) / 2)
        let yOffset = max(0, (boundsSize.height - frameSize.height) / 2)
        scrollView.contentInset = UIEdgeInsets(top: yOffset, left: xOffset, bottom: yOffset, right: xOffset)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?
        weak var scrollView: UIScrollView?
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // Center the image when zoomed
            guard let imageView = imageView else { return }
            
            let boundsSize = scrollView.bounds.size
            let contentSize = scrollView.contentSize
            
            var offsetX: CGFloat = 0
            var offsetY: CGFloat = 0
            
            if contentSize.width < boundsSize.width {
                offsetX = (boundsSize.width - contentSize.width) / 2
            }
            
            if contentSize.height < boundsSize.height {
                offsetY = (boundsSize.height - contentSize.height) / 2
            }
            
            // Update content inset to center the image
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
        }
    }
}
