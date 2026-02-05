//
//  SettingsView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var connectionStatus = "Not tested"
    @State private var isTestingConnection = false
    @State private var showingCreateAccount = false
    @State private var showingSignIn = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                accountSection
                
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
            .onAppear {
                Task {
                    await authService.refreshAuthState()
                }
            }
            .sheet(isPresented: $showingCreateAccount) {
                CreateAccountView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingSignIn) {
                SignInView()
                    .environmentObject(authService)
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authService.signOut()
                        // Sign back in anonymously to continue using the app
                        try? await authService.signInAnonymously()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out? You'll be signed in anonymously and won't have access to your synced documents until you sign back in.")
            }
        }
    }
    
    // MARK: - Account Section
    
    @ViewBuilder
    private var accountSection: some View {
        if authService.isAnonymous {
            // Anonymous user - show upgrade banner
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync Your Documents")
                                .font(.headline)
                            Text("Create an account to access your documents on all your devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: { showingCreateAccount = true }) {
                        Text("Create Account")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { showingSignIn = true }) {
                        Text("Already have an account? Sign In")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Account")
            }
        } else {
            // Signed in user - show account info
            Section("Account") {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authService.userEmail ?? "Unknown")
                            .font(.subheadline)
                        Text("Synced across devices")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 4)
                
                Button(role: .destructive) {
                    showingSignOutAlert = true
                } label: {
                    Text("Sign Out")
                }
            }
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionStatus = "Testing..."
        
        Task {
            do {
                let client = SupabaseDatabaseClient()
                // Simple test - try to read documents (will fail if connection is bad)
                _ = try await client.readDocuments(userId: UUID())
                
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

// MARK: - Create Account View

struct CreateAccountView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("Account Details")
                } footer: {
                    Text("Your existing documents will be linked to your new account.")
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: createAccount) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Create Account")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        email.contains("@")
    }
    
    private func createAccount() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Link email to the existing anonymous account
                try await authService.linkEmail(email: email, password: password)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Sign In View

struct SignInView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingResetPassword = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Sign In") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: signIn) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                    
                    Button("Forgot Password?") {
                        showingResetPassword = true
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Password", isPresented: $showingResetPassword) {
                TextField("Email", text: $email)
                Button("Cancel", role: .cancel) { }
                Button("Send Reset Email") {
                    Task {
                        try? await authService.resetPassword(email: email)
                    }
                }
            } message: {
                Text("Enter your email address and we'll send you a link to reset your password.")
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func signIn() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationService())
}
