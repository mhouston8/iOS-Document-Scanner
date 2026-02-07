//
//  RevenueCatService.swift
//  Axio Scan
//
//  Created by Matthew Houston on 2/4/26.
//

import Foundation
import Combine
import RevenueCat

@MainActor
class RevenueCatService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isPremium: Bool = false
    @Published var offerings: Offerings?
    @Published var customerInfo: CustomerInfo?
    @Published var isLoading: Bool = false
    
    // MARK: - User Identification
    
    /// Links RevenueCat user to Supabase user ID for cross-platform tracking
    func connectUserToRevenueCat(userId: String) async {
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            self.customerInfo = customerInfo
            updatePremiumStatus(customerInfo: customerInfo)
            print("RevenueCat: Identified user \(userId)")
        } catch {
            print("RevenueCat: Failed to identify user - \(error.localizedDescription)")
        }
    }
    
    /// Resets to anonymous RevenueCat user (call on sign out)
    func logOut() async {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            self.customerInfo = customerInfo
            updatePremiumStatus(customerInfo: customerInfo)
            print("RevenueCat: Logged out, reset to anonymous")
        } catch {
            print("RevenueCat: Failed to log out - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Subscription Status
    
    /// Checks current subscription status - call on app launch
    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            self.customerInfo = customerInfo
            updatePremiumStatus(customerInfo: customerInfo)
        } catch {
            print("RevenueCat: Failed to fetch customer info - \(error.localizedDescription)")
        }
    }
    
    private func updatePremiumStatus(customerInfo: CustomerInfo) {
        isPremium = customerInfo.entitlements[RevenueCatConfig.premiumEntitlement]?.isActive == true
        print("RevenueCat: Premium status = \(isPremium)")
    }
    
    // MARK: - Offerings
    
    /// Fetches available products/packages for paywall display
    func fetchOfferings() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            offerings = try await Purchases.shared.offerings()
            print("RevenueCat: Fetched offerings - \(offerings?.current?.availablePackages.count ?? 0) packages")
        } catch {
            print("RevenueCat: Failed to fetch offerings - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Purchases
    
    /// Purchase a package
    func purchase(package: Package) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let (_, customerInfo, _) = try await Purchases.shared.purchase(package: package)
        self.customerInfo = customerInfo
        updatePremiumStatus(customerInfo: customerInfo)
    }
    
    /// Restore previous purchases
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let customerInfo = try await Purchases.shared.restorePurchases()
        self.customerInfo = customerInfo
        updatePremiumStatus(customerInfo: customerInfo)
        print("RevenueCat: Restored purchases")
    }
}
