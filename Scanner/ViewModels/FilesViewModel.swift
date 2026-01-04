//
//  FilesViewModel.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class FilesViewModel: ObservableObject {
    @Published var documents: [Document] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let databaseService: DatabaseService
    private let authService: AuthenticationService
    
    init(
        databaseService: DatabaseService,
        authService: AuthenticationService
    ) {
        self.databaseService = databaseService
        self.authService = authService
    }
    
    func loadDocuments() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                guard let userId = await authService.currentUserId() else {
                    errorMessage = "No authenticated user"
                    isLoading = false
                    return
                }
                
                let fetchedDocuments = try await databaseService.fetchDocuments(userId: userId)
                documents = fetchedDocuments
                print("Loaded \(fetchedDocuments.count) documents")
            } catch {
                errorMessage = "Failed to load documents: \(error.localizedDescription)"
                print("ERROR [FilesViewModel]: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
}
