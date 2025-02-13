//
//  SettingsView.swift
//  DocMatic
//
//  Created by Paul  on 1/20/25.
//

import SwiftUI
import RevenueCat

struct SettingsView: View {
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
    
    @State private var showDebug: Bool = false
    
    @State private var debugMessage: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("General")) {
                    buttonRow(iconName: "paintbrush.fill", backgroundColor: Color("Accent"), label: "Appearance") {
                        showPickerView.toggle()
                    }
                    
                    navigationRow(iconName: "app.fill", backgroundColor: Color("Accent"), label: "App Icon", destination: AnyView(alternativeIcons()))
                }
                
                Section {
                    navigationRow(iconName: "questionmark.bubble.fill", backgroundColor: Color("Accent"), label: "Help & FAQ", destination: AnyView(HelpFAQView()))
                    
                    navigationRow(iconName: "info.circle.fill", backgroundColor: Color("Accent"), label: "Whats's New", destination: AnyView(whatsNewView()))
                }
                
                Section(header: Text("Legal"), footer: Text("Version: 1.0.0")) {
                    navigationRow(iconName: "text.document.fill", backgroundColor: Color("Accent"), label: "Terms of Use", destination: AnyView(Text("Terms of Use View")))
                    
                    navigationRow(iconName: "text.document.fill", backgroundColor: Color("Accent"), label: "Privacy Policy", destination: AnyView(Text("Privacy Policy View")))
                }
                
#if DEBUG
                Section(header: Text("Development Tools"), footer: Text(debugMessage)) { /// <-- Display the debug message
                    Button {
                        showDebug = true
                    } label: {
                        Label("RC Debug Overlay", systemImage: "ladybug")
                    }
                    
                    Button {
                        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                        UserDefaults.standard.synchronize()
                        debugMessage = "userDefaults reset successfully."
                    } label: {
                        Label("Reset User Defaults", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    }
                }
#endif
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
        .debugRevenueCatOverlay(isPresented: $showDebug)
        .animation(.easeInOut, value: appScheme)
    }
}

#Preview {
    SettingsView()
}

struct FAQView: View {
    var body: some View {
        Text("FAQ content goes here.")
            .navigationTitle("Help & FAQ")
    }
}

struct TermsAndPrivacyView: View {
    var body: some View {
        Text("Terms and Privacy content goes here.")
            .navigationTitle("Terms & Privacy")
    }
}

struct buttonRow: View {
    var iconName: String
    var backgroundColor: Color
    var label: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(backgroundColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(label)
                    .font(.headline)
                    .foregroundStyle(Color("DynamicTextColor"))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .imageScale(.small)
                    .foregroundColor(Color.init(uiColor: .systemGray3))
            }
        }
    }
}

struct navigationRow: View {
    var iconName: String
    var backgroundColor: Color
    var label: String
    var destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(backgroundColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(label)
                    .font(.headline)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
