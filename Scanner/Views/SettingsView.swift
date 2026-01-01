//
//  SettingsView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var connectionStatus = "Not tested"
    @State private var isTestingConnection = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Supabase Connection") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(connectionStatus)
                            .foregroundColor(connectionStatus == "Connected" ? .green : .secondary)
                    }
                    
                    Button(action: testConnection) {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isTestingConnection ? "Testing..." : "Test Connection")
                        }
                    }
                    .disabled(isTestingConnection)
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionStatus = "Testing..."
        
        Task {
            do {
                let client = SupabaseDatabaseClient()
                // Simple test - try to fetch documents (will fail if connection is bad)
                _ = try await client.fetchDocuments(userId: UUID())
                
                await MainActor.run {
                    connectionStatus = "Connected ✓"
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    // Connection works even if table doesn't exist
                    // If we get here, connection is established
                    if error.localizedDescription.contains("relation") || error.localizedDescription.contains("does not exist") {
                        connectionStatus = "Connected ✓ (tables not created yet)"
                    } else {
                        connectionStatus = "Error: \(error.localizedDescription)"
                    }
                    isTestingConnection = false
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
