//
//  SettingsView.swift
//  DocMatic
//
//  Created by Paul  on 1/20/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("General")) {
                    //settingsRow(iconName: "trash.fill", backgroundColor: .purple, label: "Recently Deleted") { }
                    
                    buttonRow(iconName: "paintbrush.fill", backgroundColor: .purple, label: "Appearance") {
                        showPickerView.toggle()
                    }
                    
                    navigationRow(iconName: "app.fill", backgroundColor: .purple, label: "App Icon", destination: AnyView(Text("Icon View")))
                    
                    buttonRow(iconName: "square.2.layers.3d.fill", backgroundColor: .purple, label: "Siri Shortcuts") { }
                }
                
                Section {
                    //settingsRow(iconName: "square.and.arrow.up.fill", backgroundColor: .purple, label: "Share App") { }
                    
                    navigationRow(iconName: "questionmark.bubble.fill", backgroundColor: .purple, label: "Help & FAQ", destination: AnyView(Text("Help and FAQ View")))
                }
                
                Section(header: Text("Legal")) {
                    navigationRow(iconName: "text.document.fill", backgroundColor: .purple, label: "Terms of Use", destination: AnyView(Text("Terms of Use View")))
                    
                    navigationRow(iconName: "text.document.fill", backgroundColor: .purple, label: "Privacy Policy", destination: AnyView(Text("Privacy Policy View")))
                }
                
                /*
                Section(header: Text("Integrations")) {
                    
                }
                
                Section(header: Text("Support")) {
                    
                }
                
                Section(header: Text("About")) { /// lock.shield.fill
                    
                }
                
                Section(footer: Text("Resetting the app will permanently etase all settings. This action is irreversible.")) {
                    settingsRow(iconName: "trash.fill", backgroundColor: .red, label: "Reset all settings") {
                       
                    }
                }
                 */
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
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
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
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
