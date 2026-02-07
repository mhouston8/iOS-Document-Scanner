//
//  RevenueCatConfig.swift
//  Axio Scan
//
//  Created by Matthew Houston on 2/4/26.
//

import Foundation

struct RevenueCatConfig {
    // RevenueCat API Key (from RevenueCat Dashboard > Project > API Keys)
    static let apiKey = "appl_UBslcfxAFcmvYwiMkjweWaDLqoR"
    
    // Entitlement Identifiers (configured in RevenueCat Dashboard)
    static let premiumEntitlement = "Axio Scan Premium"
    
    // Product Identifiers (must match App Store Connect)
    struct Products {
        static let monthlySubscription = "axioscan_premium_monthly"
        static let yearlySubscription = "axioscan_premium_yearly"
        // static let lifetime = "axioscan_premium_lifetime"
    }
}
