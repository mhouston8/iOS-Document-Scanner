//
//  MainTabView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingScanner = false
    @State private var scannedPages: [UIImage] = []
    @State private var showingNamingDialog = false
    @State private var documentName = ""
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                FilesView()
                    .tabItem {
                        Label("Files", systemImage: "folder.fill")
                    }
                    .tag(1)
                
                // Hidden tab for Scan - floating button handles the UI
                Color.clear
                    .tabItem {
                        Label("", systemImage: "")
                    }
                    .tag(2)
                
                ActionsView()
                    .tabItem {
                        Label("Actions", systemImage: "square.stack.3d.up.fill")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .onAppear {
                customizeTabBar()
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                // Auto-open scanner when Scan tab is selected
                if newValue == 2 {
                    showingScanner = true
                }
            }

            
            // Floating Scan button - replaces the middle tab item
            Button(action: {
                showingScanner = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: selectedTab == 2 ? [Color.blue, Color.blue.opacity(0.8)] : [Color.blue.opacity(0.9), Color.blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.blue.opacity(0.4), radius: selectedTab == 2 ? 12 : 8, x: 0, y: selectedTab == 2 ? 6 : 4)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -5)
            .scaleEffect(selectedTab == 2 ? 1.1 : 1.0)
        }
        .sheet(isPresented: $showingScanner) {
            DocumentScannerView(scannedPages: $scannedPages)
        }
        .sheet(isPresented: $showingNamingDialog) {
            DocumentNamingView(
                documentName: $documentName,
                pageCount: scannedPages.count,
                onSave: {
                    saveDocument(name: documentName, images: scannedPages)
                    scannedPages = []
                    documentName = ""
                    showingNamingDialog = false
                    selectedTab = 1 // Switch to Files tab
                },
                onCancel: {
                    scannedPages = []
                    documentName = ""
                    showingNamingDialog = false
                }
            )
        }
        .onChange(of: scannedPages) { oldValue, newValue in
            if !newValue.isEmpty {
                // Generate default name
                documentName = generateDefaultDocumentName()
                // Show naming dialog
                showingNamingDialog = true
            }
        }
    }
    
    private func generateDefaultDocumentName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Document \(formatter.string(from: Date()))"
    }
    
    private func saveDocument(name: String, images: [UIImage]) {
        // TODO: Save document to database
        // For now, just print
        print("Saving document '\(name)' with \(images.count) pages")
    }
    
    private func customizeTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Style regular tabs
        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        appearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // Hide the middle tab item (index 2) by making it invisible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let tabBarController = findTabBarController(in: window.rootViewController) {
                if let items = tabBarController.tabBar.items, items.count > 2 {
                    // Hide the middle tab item
                    items[2].title = ""
                    items[2].image = UIImage()
                }
            }
        }
    }
    
    private func findTabBarController(in viewController: UIViewController?) -> UITabBarController? {
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }
        for child in viewController?.children ?? [] {
            if let found = findTabBarController(in: child) {
                return found
            }
        }
        return nil
    }
}

#Preview {
    MainTabView()
}
