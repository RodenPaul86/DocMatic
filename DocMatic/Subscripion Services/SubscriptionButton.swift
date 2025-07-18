//
//  SubscriptionButton.swift
//  DocMatic
//
//  Created by Paul  on 2/12/25.
//

import SwiftUI
import StoreKit
import RevenueCat

// MARK: Subscription Plans
enum SubscriptionPlan: String {
    case annual = "Annually"
    case monthly = "Monthly"
    case weekly = "Weekly"
    case lifetime = "Lifetime"
}

struct SubscriptionButton: View {
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    let plan: SubscriptionPlan
    @Binding var selectedPlan: SubscriptionPlan
    var offering: Offering?
    
    @State private var currentOffering: Offering?
    
    //@StateObject private var currency = CurrencyFormatter()
    @State private var originalYearlyPrice: Double = 259.48
    
    @State private var isTrialEligible: Bool = false
    
    var isSelected: Bool {
        selectedPlan == plan
    }
    
    // MARK: Helper to extract price value
    func priceValue(for package: Package?) -> Double? {
        guard let price = package?.storeProduct.price as? NSDecimalNumber else { return nil }
        return price.doubleValue
    }
    
    // MARK: Helper to extract price
    func priceString(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .annual:
            return offering?.annual?.localizedPriceString ?? "N/A"
        case .monthly:
            return offering?.monthly?.localizedPriceString ?? "N/A"
        case .weekly:
            return offering?.weekly?.localizedPriceString ?? "N/A"
        case .lifetime:
            return offering?.lifetime?.localizedPriceString ?? "N/A"
        }
    }
    
    // MARK: Calculate the dynamic discount for the Annual Plan
    func annualDiscount() -> Int? {
        let originalAnnualPrice: Double = originalYearlyPrice
        guard let discountedAnnualPrice = priceValue(for: offering?.annual) else { return nil }
        let discount = (1 - (discountedAnnualPrice / originalAnnualPrice)) * 100
        return Int(discount.rounded())
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack { /// <-- Button title
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
                        .background(Color.theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
            Spacer()
            
            pricingView(for: plan)
        }
        .padding()
        .frame(width: 172, height: 100, alignment: .leading)
        //.frame(maxWidth: .infinity, maxHeight: plan == .lifetime ? 100 : 100, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2)) /// <-- Dark gray background
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.theme.accent : Color(.systemGray6).gradient, lineWidth: 2)
        )
        .onTapGesture {
            selectedPlan = plan
            if isHapticsEnabled {
                hapticManager.shared.notify(.impact(.light))
            }
        }
        .onAppear {
            checkTrialEligibilityIfNeeded()
        }
    }
    
    @ViewBuilder
    private func pricingView(for plan: SubscriptionPlan) -> some View {
        let price = priceString(for: plan)
        
        switch plan {
        case .annual:
            VStack(alignment: .leading, spacing: 4) {
                //Text(currency.format(originalYearlyPrice))
                Text("$259.48")
                    .foregroundStyle(Color.theme.accent)
                    .bold()
                    .strikethrough()
                Text("\(price) / yr")
                    .foregroundStyle(.primary)
                    .bold()
            }
            
        case .monthly:
            Text("\(price) / mo")
                .foregroundStyle(.primary)
                .bold()
            
        case .weekly:
            VStack(alignment: .leading, spacing: 4) {
                if isTrialEligible {
                    Text("3-Day Trial")
                        .foregroundStyle(Color.theme.accent)
                        .bold()
                }
                Text("\(price) / wk")
                    .foregroundStyle(.primary)
                    .bold()
            }
            
        case .lifetime:
            VStack(alignment: .leading, spacing: 4) {
                Text("No Renewals")
                    .foregroundStyle(Color.theme.accent)
                    .bold()
                
                Text("\(price) / once")
                    .foregroundStyle(.primary)
                    .bold()
            }
        }
    }
    
    private func checkTrialEligibilityIfNeeded() {
        guard plan == .weekly, let product = offering?.weekly?.storeProduct else { return }
        
        Purchases.shared.checkTrialOrIntroDiscountEligibility(productIdentifiers: [product.productIdentifier]) { eligibilityMap in
            if let eligibility = eligibilityMap[product.productIdentifier] {
                switch eligibility.status {
                case .eligible:
                    isTrialEligible = true
                default:
                    isTrialEligible = false
                }
            }
        }
    }
}

#Preview {
    SubscriptionView(isPaywallPresented: .constant(false))
        .preferredColorScheme(.dark)
}
