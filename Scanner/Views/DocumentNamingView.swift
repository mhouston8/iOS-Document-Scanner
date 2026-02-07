//
//  DocumentNamingView.swift
//  Axio Scan
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct DocumentNamingView: View {
    @Binding var documentName: String
    let pageCount: Int
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        AppColors.backgroundGradientStart,
                        AppColors.backgroundGradientEnd
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Icon
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.scanBlue, AppColors.scanBlue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 40)
                    
                    // Page count
                    Text("\(pageCount) page\(pageCount == 1 ? "" : "s") scanned")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    
                    // Name input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Document Name")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        TextField("Enter document name", text: $documentName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.textPrimary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .focused($isTextFieldFocused)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: onSave) {
                            Text("Save Document")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                colors: [AppColors.scanBlue, AppColors.scanBlue.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(color: AppColors.scanBlue.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .disabled(documentName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(documentName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
                        
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Name Document")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Auto-focus text field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}

#Preview {
    DocumentNamingView(
        documentName: .constant("My Document"),
        pageCount: 3,
        onSave: {},
        onCancel: {}
    )
}
