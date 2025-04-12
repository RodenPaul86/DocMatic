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
    
    init() {
        Purchases.shared.getCustomerInfo { customerInfo, error in
            self.isSubscriptionActive = customerInfo?.entitlements.all["premium"]?.isActive == true
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
        // Reset the app icon to default when the subscription is no longer active
        UIApplication.shared.setAlternateIconName(nil) // Reset to default icon
    }
}
