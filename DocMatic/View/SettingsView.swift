//
//  SettingsView.swift
//  DocMatic
//
//  Created by Paul  on 1/20/25.
//

import SwiftUI
import RevenueCat
import WebKit

struct SettingsView: View {
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
    
    @State private var showDebug: Bool = false
    @State private var debugMessage: String = ""
    
    @State private var isPaywallPresented: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Costomization")) {
                    customRow(icon: "paintbrush", firstLabel: "Appearance", secondLabel: "", action: {
                        showPickerView.toggle()
                    })
                    
                    customRow(icon: "questionmark.app.dashed", firstLabel: "Alternate Icons", secondLabel: "", destination: AnyView(alternativeIcons()))
                }
                
                Section(header: Text("App Info")) {
                    customRow(icon: "app", firstLabel: "Application", secondLabel: Bundle.main.appName)
                    customRow(icon: "curlybraces", firstLabel: "Language", secondLabel: "Swift / SwiftUI")
                    customRow(icon: "square.on.square.dashed", firstLabel: "Version", secondLabel: Bundle.main.appVersion)
                    customRow(icon: "hammer", firstLabel: "Build", secondLabel: Bundle.main.appBuild)
                    customRow(icon: "app.badge", firstLabel: "What's New", secondLabel: "", destination: AnyView(whatsNewView()))
                }
                
                Section {
                    customRow(icon: "laptopcomputer", firstLabel: "Developer", secondLabel: "Paul Roden Jr.")
                    
                    Text("DocMatic was crafted by a single dedicated indie developer, who relies on your support to grow. \n\nTogether, we'll continuously expand and enrich the experience, ensuring you always get the most out of your subscription. \n\nThank you for being a part of this journey!")
                        .font(.subheadline)
                    
                    customRow(icon: "link", firstLabel: "My Website", secondLabel: "", url: "https://paulrodenjr.org")
                    customRow(icon: "link", firstLabel: "GitHub", secondLabel: "", url: "https://github.com/RodenPaul86")
                    customRow(icon: "link", firstLabel: "Buy me a coffee", secondLabel: "", url: "https://buymeacoffee.com/paulrodenjr")
                }
                
                Section(header: Text("Support")) {
                    customRow(icon: "questionmark.bubble", firstLabel: "Help & Feedback", secondLabel: "", destination: AnyView(HelpFAQView()))
                    /*
                     customRow(icon: "lock.shield", iconBG_Color: Color("Default"), firstLabel: "Privacy & Permissions", secondLabel: "", destination: AnyView(privacyPermissions()))
                     */
                    customRow(icon: "link", firstLabel: "DocMatic Website", secondLabel: "", url: "https://docmatic.app")
                }
#if DEBUG
                Section(header: Text("Development Tools"), footer: Text(debugMessage)) { /// <-- Display the debug message
                    customRow(icon: "ladybug", firstLabel: "RC Debug Overlay", secondLabel: "") {
                        showDebug = true
                    }
                    customRow(icon: "dollarsign.circle", firstLabel: "Show Paywall for (Debuging)", secondLabel: "") {
                        isPaywallPresented.toggle()
                    }
                    .sheet(isPresented: $isPaywallPresented) {
                        SubscriptionView(isPaywallPresented: $isPaywallPresented)
                    }
                    customRow(icon: "arrow.trianglehead.2.clockwise.rotate.90", firstLabel: "Reset userDefaults", secondLabel: "") {
                        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                        UserDefaults.standard.synchronize()
                        debugMessage = "Successfully reset."
                    }
                }
#endif
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .debugRevenueCatOverlay(isPresented: $showDebug)
        .animation(.easeInOut, value: appScheme)
    }
}

#Preview {
    SettingsView()
}

struct TermsAndPrivacyView: View {
    var body: some View {
        Text("Terms and Privacy content goes here.")
            .navigationTitle("Terms & Privacy")
    }
}

struct customRow: View {
    var icon: String
    var firstLabel: String
    var firstLabelColor: Color = .gray
    var secondLabel: String
    var action: (() -> Void)? = nil  // Optional action
    var destination: AnyView? = nil  // Optional navigation
    var url: String? = nil           // Optional URL
    
    @State private var isNavigating = false
    
    var body: some View {
        if let urlString = url {
            NavigationLink {
                webView(url: urlString)
                    .edgesIgnoringSafeArea(.all)
                    .navigationTitle(firstLabel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            if let link = URL(string: urlString) {
                                Link(destination: link) {
                                    Image(systemName: "safari")
                                }
                            }
                        }
                    }
            } label: {
                rowContent(showChevron: false)
            }
            .buttonStyle(.plain)
        } else if let destination = destination {
            NavigationLink {
                destination
            } label: {
                rowContent(showChevron: false)
            }
            .buttonStyle(.plain) // Keeps it looking like a row
        } else {
            rowContent(showChevron: action != nil)
                .onTapGesture {
                    action?()
                }
        }
    }
    
    private func rowContent(showChevron: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color("Default").gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(firstLabel)
                .font(.headline)
                .foregroundStyle(Color("DynamicTextColor"))
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .imageScale(.small)
                    .foregroundColor(Color.init(uiColor: .systemGray3))
            } else {
                Text(secondLabel)
                    .font(.headline)
                    .foregroundStyle((action == nil && destination == nil && url == nil) ? .gray : Color("DynamicTextColor"))
            }
        }
        .contentShape(Rectangle())
    }
    
    private func isWebsite(_ urlString: String) -> Bool {
        return urlString.hasPrefix("http") // Simple check for URLs
    }
}

struct webView: UIViewRepresentable {
    var url: String
    func makeUIView(context: UIViewRepresentableContext<webView>) -> WKWebView {
        let view = WKWebView()
        view.load(URLRequest(url: URL(string: url)!))
        return view
    }
    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<webView>) {
    }
}
