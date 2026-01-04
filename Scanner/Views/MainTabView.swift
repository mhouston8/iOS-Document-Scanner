//
//  MainTabView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        MainTabViewContent(authService: authService)
    }
}

private struct MainTabViewContent: View {
    let authService: AuthenticationService
    @StateObject private var viewModel: MainTabViewModel
    
    init(authService: AuthenticationService) {
        self.authService = authService
        _viewModel = StateObject(wrappedValue: MainTabViewModel(authService: authService))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $viewModel.selectedTab) {
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
                
                AllActionsView()
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
            .onChange(of: viewModel.selectedTab) { oldValue, newValue in
                viewModel.handleTabSelection(newValue)
            }

            
            // Floating Scan button - replaces the middle tab item
            Button(action: {
                viewModel.openScanner()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: viewModel.selectedTab == 2 ? [Color.blue, Color.blue.opacity(0.8)] : [Color.blue.opacity(0.9), Color.blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.blue.opacity(0.4), radius: viewModel.selectedTab == 2 ? 12 : 8, x: 0, y: viewModel.selectedTab == 2 ? 6 : 4)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -5)
            .scaleEffect(viewModel.selectedTab == 2 ? 1.1 : 1.0)
        }
        .sheet(isPresented: $viewModel.showingScanner) {
            DocumentScannerView(scannedPages: $viewModel.scannedPages)
        }
        .sheet(isPresented: $viewModel.showingNamingDialog) {
            DocumentNamingView(
                documentName: $viewModel.documentName,
                pageCount: viewModel.scannedPages.count,
                onSave: {
                    viewModel.saveDocument(name: viewModel.documentName, images: viewModel.scannedPages)
                },
                onCancel: {
                    viewModel.cancelDocumentNaming()
                }
            )
        }
        .onChange(of: viewModel.scannedPages) { oldValue, newValue in
            if !newValue.isEmpty {
                viewModel.handleScannedPages(newValue)
            }
        }
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
        .environmentObject(AuthenticationService())
}
