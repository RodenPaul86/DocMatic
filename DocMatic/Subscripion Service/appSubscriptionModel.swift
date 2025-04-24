//
//  appSubscriptionModel.swift
//  DocMatic
//
//  Created by Paul  on 2/11/25.
//

import Foundation
import SwiftUI
import RevenueCat

class appSubscriptionModel: ObservableObject {
    @Published var isSubscriptionActive = false
    @Published var isLoading = true
    
    init() {
        refreshSubscriptionStatus()
    }
    
    func refreshSubscriptionStatus() {
        isLoading = true
        Purchases.shared.getCustomerInfo { customerInfo, error in
            DispatchQueue.main.async {
                let isActive = customerInfo?.entitlements.all["premium"]?.isActive == true
                self.isSubscriptionActive = isActive
                self.isLoading = false
            }
        }
    }
    
    func updateSubscriptionStatus(isActive: Bool) {
        self.isSubscriptionActive = isActive
        UserDefaults.standard.set(isActive, forKey: "isSubscriptionActive")
        
        if !isActive {
            resetAppIconToDefault()
        }
    }
    
    private func resetAppIconToDefault() {
        UIApplication.shared.setAlternateIconName(nil) /// <-- Reset to default icon
    }
}
