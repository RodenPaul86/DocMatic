//
//  SettingsView.swift
//  DocMatic
//
//  Created by Paul  on 1/20/25.
//

import SwiftUI
import RevenueCat
import WebKit
import TipKit

struct SettingsView: View {
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
    @AppStorage("resetDatastore") private var resetDatastore: Bool = false
    @AppStorage("showTipsForTesting") private var showTipsForTesting: Bool = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSubModel: appSubscriptionModel
    
    @State private var showDebug: Bool = false
    @State private var debugMessage: String = ""
    @State private var isPaywallPresented: Bool = false
    @State private var isPresentedManageSubscription: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                if !appSubModel.isSubscriptionActive {
                    customPremiumBanner {
                        isPaywallPresented = true
                        HapticManager.shared.notify(.notification(.success))
                    }
                    .listRowInsets(EdgeInsets())
                }
                
                Section(header: Text("Costomization")) {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        customRow(icon: "paintbrush", firstLabel: "Appearance", secondLabel: "", action: {
                            showPickerView.toggle()
                        })
                    }
                    
                    customRow(icon: "questionmark.app.dashed", firstLabel: "Alternate Icons", secondLabel: "", destination: AnyView(alternativeIcons()))
                }
                
                Section(header: Text("Support")) {
                    customRow(icon: "questionmark.bubble", firstLabel: "Frequently Asked Questions", secondLabel: "", destination: AnyView(helpFAQView()))
                    customRow(icon: "envelope", firstLabel: "Contact Support", secondLabel: "", destination: AnyView(feedbackView()))
                    /*
                     customRow(icon: "lock.shield", iconBG_Color: Color("Default"), firstLabel: "Privacy & Permissions", secondLabel: "", destination: AnyView(privacyPermissions()))
                     */
                }
                
                Section(header: Text("Info")) {
                    customRow(icon: "info", firstLabel: "About", secondLabel: "", destination: AnyView(aboutView()))
                    
                    if appSubModel.isSubscriptionActive {
                        customRow(icon: "crown", firstLabel: "Manage Subscription", secondLabel: "") {
                            isPresentedManageSubscription = true
                        }
                    }
                    
                    if AppReviewRequest.showReviewButton, let url = AppReviewRequest.appURL(id: "id6740615012") {
                        customRow(icon: "star.bubble", firstLabel: "Rate & Review \(Bundle.main.appName)", secondLabel: "") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    customRow(icon: "square.and.arrow.up", firstLabel: "Share with Freinds", secondLabel: "", shareURL: URL(string: "https://apps.apple.com/app/docmatic-file-scanner/id6740615012"))
                    
                    customRow(icon: "app.badge", firstLabel: "Release Notes", secondLabel: "", destination: AnyView(releaseNotesView()))
                }
                
                Section(header: Text("Legal")) {
                    customRow(icon: "link", firstLabel: "Privacy Policy", secondLabel: "", url: "https://docmatic.app/privacy.html")
                    customRow(icon: "link", firstLabel: "Terms of Service", secondLabel: "", url: "https://docmatic.app/terms.html")
                    customRow(icon: "link", firstLabel: "EULA", secondLabel: "", url: "https://docmatic.app/EULA.html")
                }
#if DEBUG
                Section(header: Text("Development Tools"), footer: Text(debugMessage)) { /// <-- Display the debug message
                    let scanCount = UserDefaults.standard.value(forKey: "scanCount")
                    customRow(icon: "scanner", firstLabel: "\(scanCount ?? "0") Document\(scanCount as? Int != 1 ? "s" : "") Scanned", secondLabel: "")
                    
                    customRow(icon: "ladybug", firstLabel: "RC Debug Overlay", secondLabel: "") {
                        showDebug = true
                    }
                    
                    customRow(icon: "exclamationmark.arrow.trianglehead.counterclockwise.rotate.90", firstLabel: "Reset userDefaults", secondLabel: "") {
                        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                        UserDefaults.standard.synchronize()
                        debugMessage = "Success!!"
                    }
                    
                    customRow(icon: "arrow.trianglehead.2.clockwise.rotate.90", firstLabel: "Reset Datastore", secondLabel: "", showToggle: true, toggleValue: $resetDatastore)
                    
                    customRow(icon: "lightbulb.max", firstLabel: "Show Tips For Testing", secondLabel: "", showToggle: true, toggleValue: $showTipsForTesting)
                }
#endif
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Button(action: { dismiss() }) {
                            Text("Done")
                                .foregroundStyle(Color("Default").gradient)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $isPaywallPresented) {
                SubscriptionView(isPaywallPresented: $isPaywallPresented)
                    .preferredColorScheme(.dark)
            }
            .manageSubscriptionsSheet(isPresented: $isPresentedManageSubscription)
            .animation(.easeInOut, value: appScheme)
            //.debugRevenueCatOverlay(isPresented: $showDebug)
        }
    }
}

#Preview {
    SettingsView()
}

struct customRow: View {
    var icon: String
    var firstLabel: String
    var firstLabelColor: Color = .gray
    var secondLabel: String
    var action: (() -> Void)? = nil  /// <-- Optional action
    var destination: AnyView? = nil  /// <-- Optional navigation
    var url: String? = nil           /// <-- Optional URL
    var showToggle: Bool = false
    var toggleValue: Binding<Bool>? = nil /// <-- Optional toggle switch
    var shareURL: URL? = nil             /// <-- Optional share link
    
    @State private var isNavigating = false
    @State private var isSharing = false
    
    var body: some View {
        Group {
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
                .buttonStyle(.plain)
            } else if showToggle {
                rowContent(showChevron: false)
            } else {
                rowContent(showChevron: action != nil || shareURL != nil)
                    .onTapGesture {
                        if shareURL != nil {
                            isSharing = true
                        } else {
                            action?()
                        }
                    }
            }
        }
        .sheet(isPresented: $isSharing) {
            if let shareURL = shareURL {
                ActivityView(activityItems: [shareURL])
            }
        }
    }
    
    private func rowContent(showChevron: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18)) /// <-- Fixed size, unaffected by user settings
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color("Default").gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(firstLabel)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            if showToggle, let binding = toggleValue {
                Toggle("", isOn: binding)
                    .labelsHidden()
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .imageScale(.small)
                    .foregroundColor(Color.init(uiColor: .systemGray3))
            } else {
                Text(secondLabel)
                    .foregroundStyle((action == nil && destination == nil && url == nil && shareURL == nil) ? .gray : .primary)
            }
        }
        .contentShape(Rectangle())
    }
    
    private func isWebsite(_ urlString: String) -> Bool {
        return urlString.hasPrefix("http")
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: WebView
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

// MARK: Custom Banner
struct customPremiumBanner: View {
    var onTap: () -> Void
    
    let features = [
        "Unlimited Scans",
        "and more"
    ]
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(Bundle.main.appName) Pro")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    
                    ForEach(features, id: \.self) { feature in
                        Text("- \(feature)")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .opacity(0.7)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Image(systemName: "document.viewfinder")
                        .font(.system(size: 70)) /// <-- Originally the size was 80
                        .foregroundStyle(.white)
                        .opacity(0.1)
                        .rotationEffect(.degrees(-20))
                        .scaleEffect(1.8) /// <-- Make it larger without affecting layout
                        .offset(x: -10, y: 20)
                        .allowsHitTesting(false) /// <-- Avoids affecting taps
                    
                    HStack {
                        Image(systemName: "laurel.leading")
                        Image(systemName: "laurel.trailing")
                    }
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("Default"), Color("Default").opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle()) /// <-- Prevents default blue button style
    }
}
