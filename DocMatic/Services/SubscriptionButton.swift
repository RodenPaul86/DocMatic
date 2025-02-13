//
//  SubscriptionButton.swift
//  DocMatic
//
//  Created by Paul  on 2/12/25.
//

import SwiftUI
import RevenueCat

// Enum for Subscription Plans
enum SubscriptionPlan: String {
    case annual = "Annual"
    case monthly = "Monthly"
    case lifetime = "Lifetime"
}

struct SubscriptionButton: View {
    let plan: SubscriptionPlan
    @Binding var selectedPlan: SubscriptionPlan
    var offering: Offering?
    
    @State private var currentOffering: Offering?
    
    var isSelected: Bool {
        selectedPlan == plan
    }
    
    // Helper to extract price value
    func priceValue(for package: Package?) -> Double? {
        guard let price = package?.storeProduct.price as? NSDecimalNumber else { return nil }
        return price.doubleValue
    }
    
    // Helper to extract price
    func priceString(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .annual:
            return offering?.annual?.localizedPriceString ?? "N/A"
        case .monthly:
            return offering?.monthly?.localizedPriceString ?? "N/A"
        case .lifetime:
            return offering?.lifetime?.localizedPriceString ?? "N/A"
        }
    }
    
    // Calculate the dynamic discount for the Annual Plan
    func annualDiscount() -> Int? {
        guard let monthlyPrice = priceValue(for: offering?.monthly),
              let annualPrice = priceValue(for: offering?.annual) else { return nil }
        
        let monthlyEquivalent = annualPrice / 12
        let discount = (1 - (monthlyEquivalent / monthlyPrice)) * 100
        return Int(discount.rounded()) // Rounds to the nearest whole number
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(plan.rawValue)
                    .foregroundColor(.white)
                    .font(.headline)
                
                if plan == .annual, let discount = annualDiscount() {
                    Spacer()
                    Text("-\(discount)%")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
            Spacer()
            
            // Use helper function for price display
            let price = priceString(for: plan)
            
            // Display the appropriate price
            if plan == .annual {
                Text("\(price) / year")
                    .foregroundColor(.white)
                    .bold()
            } else if plan == .monthly {
                Text("\(price) / month")
                    .foregroundColor(.white)
                    .bold()
            } else if plan == .lifetime {
                Text("\(price) one-time")
                    .foregroundColor(.white)
                    .bold()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: plan == .lifetime ? 50 : 100, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2)) /// <-- Dark gray background
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.purple : Color.gray, lineWidth: 2)
        )
        .onTapGesture {
            selectedPlan = plan
        }
    }
}
