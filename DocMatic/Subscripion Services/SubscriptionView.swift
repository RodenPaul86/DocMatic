//
//  SubscriptionView.swift
//  DocMatic
//
//  Created by Paul  on 2/12/25.
//

import SwiftUI
import RevenueCat
import WidgetKit

struct SubscriptionView: View {
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var isPaywallPresented: Bool
    @State private var selectedPlan: SubscriptionPlan = .weekly
    @State private var currentOffering: Offering?
    @State private var isLoading: Bool = true
    @State private var showLegal: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var introOfferAvailable: Bool = false
    
    var body: some View {
        VStack {
            // MARK: Custom Navigation Bar
            HStack {
                // Restore Button
                Button(action: {
                    restorePurchases()
                }) {
                    Text("Restore")
                        .foregroundStyle(.gray.opacity(0.5))
                        .bold()
                }
                
                Spacer()
                
                // MARK: Title: DocMatic
                Text(Bundle.main.appName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Pro")
                    .font(.caption.italic().bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                // MARK: Close Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .tint(Color(.lightGray))
                        .opacity(0.25)
                }
            }
            .padding([.top, .horizontal])
            
            Spacer()
            
            if isLoading {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea() // Optional background overlay to dim the screen
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white)) // Circular spinner
                        
                        Text("Loading...")
                            .font(.headline)
                            .foregroundColor(.white) // Text color
                            .padding(.top, 10) // Padding between the spinner and text
                    }
                    .frame(width: 120, height: 120) // Increased size
                    .background(Color.gray.opacity(0.2)) // Background color for ProgressView
                    .cornerRadius(10) // Rounded corners
                    .shadow(radius: 5) // Optional shadow for better visibility
                }
            } else {
                // MARK: Feature List
                ScrollView(.vertical, showsIndicators: false) {
                    PricingView()
                        .padding([.top, .horizontal])
                }
                
                // MARK: Subscription Options and Subscribe button
                VStack {
                    // Annualy, Weekly & Lifetime offers
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            SubscriptionButton(plan: .annual, selectedPlan: $selectedPlan, offering: currentOffering)
                            SubscriptionButton(plan: .weekly, selectedPlan: $selectedPlan, offering: currentOffering)
                            SubscriptionButton(plan: .lifetime, selectedPlan: $selectedPlan, offering: currentOffering)
                        }
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollClipDisabled()
                    
                    // MARK: Subscribe Button (Full Width)
                    Button(action: {
                        purchase(selectedPlan)
                        if isHapticsEnabled {
                            hapticManager.shared.notify(.impact(.light))
                        }
                    }) {
                        Text(introOfferAvailable ? "Try for Free!" : "Subscribe")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.theme.accent, in: .capsule)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.top)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Restore Purchases"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            fetchOfferings()
            updateIntroOffer()
        }
        .onChange(of: selectedPlan) { oldValue, newValue in
            updateIntroOffer()
        }
    }
    
    // MARK: Fetch offerings from RevenueCat
    func fetchOfferings() {
        Purchases.shared.getOfferings { offerings, error in
            if let offerings = offerings {
                self.currentOffering = offerings.current
                self.updateIntroOffer()
            } else {
                print("Error fetching offerings: \(String(describing: error))")
            }
            self.isLoading = false
        }
    }
    
    // MARK: Handle restore purchases
    func restorePurchases() {
        isLoading = true
        Purchases.shared.restorePurchases { (completed, error) in
            isLoading = false
            
            if let completed = completed {
                let isActive = completed.entitlements.all["premium"]?.isActive == true
                appSubModel.isSubscriptionActive = isActive
                
                if isActive {
                    alertMessage = "Thank you! Your subscription has been successfully restored."
                    isPaywallPresented = false
                    WidgetCenter.shared.reloadAllTimelines()
                } else {
                    alertMessage = "No active subscription was found to restore."
                }
            } else {
                alertMessage = "Something went wrong: \(error?.localizedDescription ?? "Unknown error")"
            }
            showAlert = true
        }
    }
    
    // MARK: Handle subscription purchase
    func purchase(_ plan: SubscriptionPlan) {
        guard let offering = currentOffering else { return }
        
        let product: Package?
        
        switch plan {
        case .annual:
            product = offering.annual
        case .monthly:
            product = offering.monthly
        case .weekly:
            product = offering.weekly
        case .lifetime:
            product = offering.lifetime
        }
        
        isLoading = true  /// <-- Show loading state before purchase starts
        
        if let product = product {
            Purchases.shared.purchase(package: product) { (transaction, info, error, userCancelled) in
                if let error = error {
                    print("Error purchasing: \(error.localizedDescription)")
                    isLoading = false
                } else if userCancelled {
                    print("User cancelled purchase.")
                    isLoading = false
                } else if let transaction = transaction {
                    print("Purchase successful: \(transaction)")
                    
                    // Check if the subscription is active
                    if info?.entitlements.all["premium"]?.isActive == true {
                        appSubModel.isSubscriptionActive = true
                        isPaywallPresented = false
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
        }
    }
    
    func updateIntroOffer() {
        introOfferAvailable = hasIntroOffer(for: selectedPlan)
    }
    
    func hasIntroOffer(for plan: SubscriptionPlan) -> Bool {
        guard let package = getPackage(for: plan) else { return false }
        return package.storeProduct.introductoryDiscount != nil
    }
    
    func getPackage(for plan: SubscriptionPlan) -> Package? {
        guard let offering = currentOffering else { return nil }
        
        switch plan {
        case .annual:
            return offering.annual
        case .monthly:
            return offering.monthly
        case .weekly:
            return offering.weekly
        case .lifetime:
            return offering.lifetime
        }
    }
}

#Preview {
    SubscriptionView(isPaywallPresented: .constant(false))
        .preferredColorScheme(.dark)
}
