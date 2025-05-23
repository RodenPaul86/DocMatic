//
//  Extension.swift
//  DocMatic
//
//  Created by Paul  on 2/11/25.
//

import Foundation
import RevenueCat
import StoreKit

/* Some methods to make displaying subscription terms easier */

extension Package {
    func terms(for package: Package) -> String {
        if let intro = package.storeProduct.introductoryDiscount {
            let period = intro.subscriptionPeriod
            if intro.price == 0 {
                return "\(period.periodTitle) free trial"
            } else {
                return "\(package.localizedIntroductoryPriceString!) for \(period.periodTitle)"
            }
        } else {
            return "Unlocks Premium"
        }
    }
}

extension RevenueCat.SubscriptionPeriod {
    var durationTitle: String {
        switch self.unit {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        @unknown default: return "Unknown"
        }
    }
    
    var periodTitle: String {
        let periodString = "\(self.value) \(self.durationTitle)"
        let pluralized = self.value > 1 ? periodString + "s" : periodString
        return pluralized
    }
}

