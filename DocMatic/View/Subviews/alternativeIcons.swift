//
//  alternativeIcons.swift
//  DocMatic
//
//  Created by Paul  on 1/24/25.
//

import SwiftUI

enum AppIcon: String, CaseIterable {
    case appIcon = "Default"
    case appIcon1 = "Light"
    case appIcon2 = "Dark"
    
    var iconValue: String? {
        if self == .appIcon {
            return nil
        } else {
            return rawValue
        }
    }
    
    var previewImage: String {
        switch self {
        case .appIcon: "Logo1"
        case .appIcon1: "Logo2"
        case .appIcon2: "Logo3"
        }
    }
}

struct alternativeIcons: View {
    @State private var currentAppIcon: AppIcon = .appIcon
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @State private var isPaywallPresented: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Choose an App Icon") {
                    ForEach(AppIcon.allCases, id: \.rawValue) { icon in
                        AppIconRow(
                            icon: icon,
                            currentAppIcon: $currentAppIcon,
                            isSubscriptionActive: appSubModel.isSubscriptionActive,
                            isPaywallPresented: $isPaywallPresented
                        )
                    }
                }
            }
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $isPaywallPresented) {
                Alert(
                    title: Text("Upgrade to Unlock"),
                    message: Text("Unlock more app icons by subscribing!"),
                    primaryButton: .default(Text("Subscribe")) {
                        isPaywallPresented = true
                    },
                    secondaryButton: .cancel()
                )
            }
            .fullScreenCover(isPresented: $isPaywallPresented) {
                SubscriptionView(isPaywallPresented: $isPaywallPresented)
                    .preferredColorScheme(.dark)
            }
        }
        .onAppear {
            // Check for the current icon on view appearance, and only reset if needed
            if let alternativeAppIcon = UIApplication.shared.alternateIconName,
               let appIcon = AppIcon.allCases.first(where: { $0.rawValue == alternativeAppIcon }) {
                currentAppIcon = appIcon
            } else {
                currentAppIcon = AppIcon.appIcon
            }
        }
    }
}

struct AppIconRow: View {
    let icon: AppIcon
    @Binding var currentAppIcon: AppIcon
    let isSubscriptionActive: Bool
    @Binding var isPaywallPresented: Bool
    
    var body: some View {
        let isLocked = (icon != .appIcon && !isSubscriptionActive)
        let isSelected = (currentAppIcon == icon)
        
        HStack(spacing: 15) {
            ZStack {
                Image(icon.previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color("Default").gradient : Color.gray.gradient, lineWidth: 1)
                    )
            }
            
            Text(icon.rawValue)
                .fontWeight(.semibold)
            
            Spacer(minLength: 0)
            
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundColor(.red)
            } else {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color("Default").gradient : Color.gray.gradient)
            }
        }
        .contentShape(.rect)
        .onTapGesture {
            if !isLocked {
                currentAppIcon = icon
                UIApplication.shared.setAlternateIconName(icon.iconValue)
            } else {
                isPaywallPresented = true
            }
            HapticManager.shared.notify(.impact(.light))
        }
    }
}

#Preview {
    alternativeIcons()
}
