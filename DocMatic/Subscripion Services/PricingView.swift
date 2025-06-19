//
//  PricingView.swift
//  DocMatic
//
//  Created by Paul  on 2/12/25.
//

import SwiftUI

struct PricingView: View {
    let features: [(name: String, free: String?, proType: ProFeatureType, freeHasAccess: Bool)] = [
        ("Scan Documents", "3", .infinity, true),
        ("Drag & Drop PDF Files", "3", .infinity, true),
        ("Remove Watermark", nil, .checkmark, false),
        ("Lock/Home Screen Widgets", nil, .checkmark, true),
        ("Alternate App Icons", nil, .checkmark, false),
        ("Remove Annoying Paywalls", nil, .checkmark, false),
        ("Support Indie Developers", nil, .checkmark, false)
    ]
    
    enum ProFeatureType {
        case infinity, checkmark
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: Header
            HStack {
                Text("Features")
                    .font(.headline)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Free")
                    .font(.headline)
                    .foregroundStyle(.gray)
                    .frame(width: 50) /// <-- Fixed width for alignment
                
                Text("Pro")
                    .font(.headline.italic())
                    .foregroundStyle(Color("Default").gradient)
                    .frame(width: 50) /// <-- Fixed width for alignment
            }
            
            Divider()
            
            // MARK: Feature List
            ForEach(features, id: \.name) { feature in
                HStack {
                    // Feature Name
                    Text(feature.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    // Free Version Column
                    if let freeValue = feature.free {
                        Text(freeValue)
                            .frame(width: 50, alignment: .center)
                            .foregroundStyle(.gray)
                    } else {
                        Image(systemName: feature.freeHasAccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(feature.freeHasAccess ? Color("Default").gradient : Color.red.gradient)
                            .frame(width: 50)
                    }
                    
                    // Pro Version Column
                    Image(systemName: feature.proType == .infinity ? "infinity" : "checkmark.circle.fill")
                        .foregroundStyle(Color("Default").gradient)
                        .frame(width: 50)
                }
                .padding(.vertical, 5)
            }
            
            Divider()
            
            Text("All Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. You can manage your subscription or cancel anytime in your iTunes settings or in the app settings.")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .font(.subheadline)
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
    }
}

#Preview {
    SubscriptionView(isPaywallPresented: .constant(false))
        .preferredColorScheme(.dark)
}
