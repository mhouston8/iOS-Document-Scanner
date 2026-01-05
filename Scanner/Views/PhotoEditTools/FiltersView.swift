//
//  FiltersView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct FiltersView: View {
    let image: UIImage
    @Binding var editedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFilter: Filter? = nil
    @State private var filterIntensity: Double = 1.0
    @State private var currentImage: UIImage
    
    enum Filter: String, CaseIterable {
        case original = "Original"
        case blackWhite = "B&W"
        case vintage = "Vintage"
        case cool = "Cool"
        case warm = "Warm"
        case sepia = "Sepia"
        case dramatic = "Dramatic"
        case noir = "Noir"
    }
    
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
            
            Text("Filters")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Apply") {
                applyFilter()
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
            Image(uiImage: currentImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 0) {
            // Filter Intensity Slider (if filter selected)
            if selectedFilter != nil && selectedFilter != .original {
                VStack(spacing: 12) {
                    Text("Intensity")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Slider(value: $filterIntensity, in: 0...1)
                        .tint(.blue)
                        .onChange(of: filterIntensity) { oldValue, newValue in
                            applyFilterPreview()
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.8))
            }
            
            // Filter Selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Filter.allCases, id: \.self) { filter in
                        filterPreviewButton(filter: filter)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.black.opacity(0.7))
        }
    }
    
    private func filterPreviewButton(filter: Filter) -> some View {
        Button(action: {
            withAnimation {
                selectedFilter = filter
                filterIntensity = 1.0
                applyFilterPreview()
            }
        }) {
            VStack(spacing: 8) {
                // Filter preview thumbnail
                Image(uiImage: applyFilterToImage(image, filter: filter, intensity: 1.0))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 70)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedFilter == filter ? Color.blue : Color.clear, lineWidth: 3)
                    )
                
                Text(filter.rawValue)
                    .font(.caption)
                    .foregroundColor(selectedFilter == filter ? .blue : .white)
            }
        }
    }
    
    // MARK: - Actions
    
    private func applyFilterPreview() {
        guard let filter = selectedFilter else { return }
        currentImage = applyFilterToImage(image, filter: filter, intensity: filterIntensity)
    }
    
    private func applyFilterToImage(_ image: UIImage, filter: Filter, intensity: Double) -> UIImage {
        // TODO: Apply actual filter effects
        // For now, return original image
        return image
    }
    
    private func applyFilter() {
        editedImage = currentImage
        dismiss()
    }
}

#Preview {
    FiltersView(
        image: UIImage(systemName: "photo")!,
        editedImage: .constant(nil)
    )
}
