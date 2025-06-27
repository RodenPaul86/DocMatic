//
//  alternativeIcons.swift
//  DocMatic
//
//  Created by Paul  on 1/24/25.
//

import SwiftUI

enum AppIcon: String, CaseIterable {
    case defaultIcon = "Default"
    case lightIcon = "Light"
    case darkIcon = "Dark"
    case sunbeamIcon = "Sunbeam"
    case peachPopIcon = "Peach Pop"
    case firestarterIcon = "Firestarter"
    case roseEmberIcon = "Rose Ember"
    case jungleWalkIcon = "Jungle Walk"
    case pineMistIcon = "Pine Mist"
    case indigoPulseIcon = "Indigo Pulse"
    case oceanDriftIcon  = "Ocean Drift"
    case electricTideIcon = "Electric Tide"
    case frostedBlueIcon = "Frosted Blue"
    case stormWalkIcon = "Storm Walk"
    case shadowStepIcon = "Shadow Step"
    
    var iconValue: String? {
        self == .defaultIcon ? nil : rawValue
    }
    
    var previewImage: String {
        switch self {
        case .defaultIcon: "Logo0"
        case .lightIcon: "Logo1"
        case .darkIcon: "Logo2"
        case .sunbeamIcon: "Logo3"
        case .peachPopIcon: "Logo4"
        case .firestarterIcon: "Logo5"
        case .roseEmberIcon: "Logo6"
        case .jungleWalkIcon: "Logo7"
        case .pineMistIcon: "Logo8"
        case .indigoPulseIcon: "Logo9"
        case .oceanDriftIcon : "Logo10"
        case .electricTideIcon: "Logo11"
        case .frostedBlueIcon: "Logo12"
        case .stormWalkIcon: "Logo13"
        case .shadowStepIcon: "Logo14"
        }
    }
    
    static var mainIcons: [AppIcon] {
        [.defaultIcon, .lightIcon, .darkIcon]
    }
    
    static var warmIcons: [AppIcon] {
        [.sunbeamIcon, .peachPopIcon, .firestarterIcon, .roseEmberIcon]
    }
    
    static var greenBlueIcons: [AppIcon] {
        [.jungleWalkIcon, .pineMistIcon, .indigoPulseIcon, .oceanDriftIcon ]
    }
    
    static var bluesNeutralIcons: [AppIcon] {
        [.electricTideIcon, .frostedBlueIcon, .stormWalkIcon, .shadowStepIcon]
    }
}

struct alternativeIcons: View {
    @State private var currentAppIcon: AppIcon = .defaultIcon
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @State private var isPaywallPresented: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section("Original") {
                        ForEach(AppIcon.mainIcons, id: \.rawValue) { icon in
                            AppIconRow(
                                icon: icon,
                                currentAppIcon: $currentAppIcon,
                                isSubscriptionActive: appSubModel.isSubscriptionActive,
                                isPaywallPresented: $isPaywallPresented
                            )
                        }
                    }
                    
                    Section("Oranges & Reds") {
                        ForEach(AppIcon.warmIcons, id: \.rawValue) { icon in
                            AppIconRow(
                                icon: icon,
                                currentAppIcon: $currentAppIcon,
                                isSubscriptionActive: appSubModel.isSubscriptionActive,
                                isPaywallPresented: $isPaywallPresented
                            )
                        }
                    }
                    
                    Section("Greens & Blues") {
                        ForEach(AppIcon.greenBlueIcons, id: \.rawValue) { icon in
                            AppIconRow(
                                icon: icon,
                                currentAppIcon: $currentAppIcon,
                                isSubscriptionActive: appSubModel.isSubscriptionActive,
                                isPaywallPresented: $isPaywallPresented
                            )
                        }
                    }
                    
                    Section("Blues & Neutrals") {
                        ForEach(AppIcon.bluesNeutralIcons, id: \.rawValue) { icon in
                            AppIconRow(
                                icon: icon,
                                currentAppIcon: $currentAppIcon,
                                isSubscriptionActive: appSubModel.isSubscriptionActive,
                                isPaywallPresented: $isPaywallPresented
                            )
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: 80) /// <-- Reserve space for the tab bar
                }
            }
            .navigationTitle("Alternate Icons")
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
                currentAppIcon = AppIcon.defaultIcon
            }
        }
    }
}

struct AppIconRow: View {
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    let icon: AppIcon
    @Binding var currentAppIcon: AppIcon
    let isSubscriptionActive: Bool
    @Binding var isPaywallPresented: Bool
    
    var body: some View {
        let isLocked = (icon != .defaultIcon && !isSubscriptionActive)
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
                            .stroke(isSelected ? Color("Default").gradient : Color(.systemGray6).gradient, lineWidth: 1)
                    )
            }
            
            Text(icon.rawValue)
                .fontWeight(.semibold)
            
            Spacer(minLength: 0)
            
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.title)
                    .foregroundColor(.red)
            } else {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "")
                    .font(.title)
                    .foregroundStyle(isSelected ? Color("Default").gradient : Color(.systemGray6).gradient)
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
            if isHapticsEnabled {
                hapticManager.shared.notify(.impact(.light))
            }
        }
    }
}

#Preview {
    alternativeIcons()
}
