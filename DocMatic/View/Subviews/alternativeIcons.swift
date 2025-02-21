//
//  alternativeIcons.swift
//  DocMatic
//
//  Created by Paul  on 1/24/25.
//

import SwiftUI

enum AppIcon: String, CaseIterable {
    case appIcon = "Default"
    case appIcon2 = "Lavender"
    case appIcon3 = "Neptune"
    case appIcon4 = "Serpent"
    case appIcon5 = "Celestial"
    case appIcon6 = "Ember"
    case appIcon7 = "Molten"
    case appIcon8 = "Starlight"
    case appIcon9 = "Obsidian"
    
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
        case .appIcon2: "Logo2"
        case .appIcon3: "Logo3"
        case .appIcon4: "Logo4"
        case .appIcon5: "Logo5"
        case .appIcon6: "Logo6"
        case .appIcon7: "Logo7"
        case .appIcon8: "Logo8"
        case .appIcon9: "Logo9"
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
                        HStack(spacing: 15) {
                            ZStack {
                                Image(icon.previewImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(currentAppIcon == icon ? Color("Default") : .gray, lineWidth: 2)
                                    )
                            }
                            
                            Text(icon.rawValue)
                                .fontWeight(.semibold)
                            
                            Spacer(minLength: 0)
                            
                            // Show padlock icon for locked icons (not the first one)
                            if icon != .appIcon && !appSubModel.isSubscriptionActive {
                                Image(systemName: "lock.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                            } else {
                                Image(systemName: currentAppIcon == icon ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(currentAppIcon == icon ? Color("Default") : .gray)
                            }
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            if appSubModel.isSubscriptionActive || icon == .appIcon {
                                currentAppIcon = icon
                                UIApplication.shared.setAlternateIconName(icon.iconValue)
                            } else {
                                isPaywallPresented = true // Trigger the sheet for the paywall
                            }
                        }
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
            // Check for current icon on view appearance, and only reset if needed
            if let alternativeAppIcon = UIApplication.shared.alternateIconName,
               let appIcon = AppIcon.allCases.first(where: { $0.rawValue == alternativeAppIcon }) {
                currentAppIcon = appIcon
            } else {
                currentAppIcon = AppIcon.appIcon
            }
        }
    }
}

#Preview {
    alternativeIcons()
}
