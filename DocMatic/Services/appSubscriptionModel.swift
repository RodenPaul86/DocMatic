//
//  appSubModel.swift
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
}
