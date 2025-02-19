//
//  PricingView.swift
//  DocMatic
//
//  Created by Paul  on 2/12/25.
//

import SwiftUI

struct PricingView: View {
    let features: [(name: String, free: String?, proType: ProFeatureType, freeHasAccess: Bool)] = [
        ("Scanned Documents", "5", .infinity, true),
        ("Alternate App Icons", nil, .checkmark, false)
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
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Free")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(width: 50) /// <-- Fixed width for alignment
                
                Text("Pro")
                    .font(.headline)
                    .foregroundColor(.purple)
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
                            .foregroundColor(feature.freeHasAccess ? .purple : .red)
                            .frame(width: 50)
                    }
                    
                    // Pro Version Column
                    Image(systemName: feature.proType == .infinity ? "infinity" : "checkmark.circle.fill")
                        .foregroundColor(.purple)
                        .frame(width: 50)
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
    }
}

struct PricingView_Previews: PreviewProvider {
    static var previews: some View {
        PricingView()
            .preferredColorScheme(.dark)
    }
}
