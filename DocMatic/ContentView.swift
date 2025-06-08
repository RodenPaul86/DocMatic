//
//  ContentView.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI
import VisionKit

enum ScannerError: Error {
    case cameraAccessDenied
    case scanFailed
    case unknownError
}

enum Tab: Int {
    case home, settings, scanner
}

struct ContentView: View {
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @State private var showScannerView: Bool = false
    @State private var isPaywallPresented: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var scanDocument: VNDocumentCameraScan?
    @State private var askDocumentName: Bool = false
    @State private var isLoading: Bool = false
    @State private var documentName: String = "New Document"
    @Environment(\.modelContext) private var context
    @Environment(\.requestReview) var requestReview
    
    @State private var selectedTab: Tab = .home
    @State private var isCameraViewShowing: Bool = false
    
    @State private var showTabBar: Bool = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    Home(showTabBar: $showTabBar)
                case .settings:
                    SettingsView()
                default:
                    Home(showTabBar: .constant(true))
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            
            // Your custom tab bar view
            Group {
                if showTabBar {
                    bottomTabBarView(selectedTab: $selectedTab,
                                     isCameraViewShowing: $isCameraViewShowing,
                                     showScannerView: $showScannerView,
                                     isPaywallPresented: $isPaywallPresented)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        )
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 22)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showTabBar)
            .offset(y: showTabBar ? 0 : 200) // slide it down when hidden
            .opacity(showTabBar ? 1 : 0)     // fade it out when hidden
            
        }
        .ignoresSafeArea()
        
        /*
        TabView(selection: $selectedTab) {
            Tab(value: 0) {
                Home(showToolbar: $showToolbar)
            }
            
            Tab(value: 1) {
                SettingsView()
            }
        }
        .tabViewStyle(.automatic)
        .overlay(alignment: .bottom) {
            Group {
                if showToolbar {
                    bottomTabBarView(selectedTab: $selectedTab,
                                     isCameraViewShowing: $isCameraViewShowing,
                                     showScannerView: $showScannerView,
                                     isPaywallPresented: $isPaywallPresented)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        )
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showToolbar)
        }
        .ignoresSafeArea()
         */
        .fullScreenCover(isPresented: $showScannerView) {
            ScannerView { error in
                handleScannerError(error)
            } didCancel: {
                showScannerView = false
            } didFinish: { scan in
                scanDocument = scan
                showScannerView = false
                askDocumentName = true
            }
            .ignoresSafeArea()
        }
        .alert("Document Name", isPresented: $askDocumentName) {
            TextField("New Document", text: $documentName)
            Button("Save") { createDocument() }
                .disabled(documentName.isEmpty)
        }
        .loadingScreen(status: $isLoading)
        .fullScreenCover(isPresented: $isPaywallPresented) {
            SubscriptionView(isPaywallPresented: $isPaywallPresented)
                .preferredColorScheme(.dark)
        }
    }
    
    // MARK: Helper Methods
    private func createDocument() {
        guard let scanDocument else { return }
        isLoading = true
        Task.detached(priority: .high) { [documentName] in
            let document = Document(name: documentName)
            var pages: [DocumentPage] = []
            
            for pageIndex in 0..<scanDocument.pageCount {
                let pageImage = scanDocument.imageOfPage(at: pageIndex)
                guard let pageData = pageImage.jpegData(compressionQuality: 0.65) else { return }
                let documentPage = DocumentPage(document: document, pageIndex: pageIndex, pageData: pageData)
                pages.append(documentPage)
            }
            document.pages = pages
            
            await MainActor.run {
                ScanManager.shared.incrementScanCount()
                
                context.insert(document)
                try? context.save()
                
                self.scanDocument = nil
                isLoading = false
                self.documentName = "New Document"
                
                if AppReviewRequest.requestAvailable {
                    Task {
                        try await Task.sleep(
                            until: .now + .seconds(1),
                            tolerance: .seconds(0.5),
                            clock: .suspending
                        )
                        requestReview()
                    }
                }
            }
        }
    }
    
    // MARK: Error Handling
    func handleScannerError(_ error: Error) {
        var errorMessage: String
        
        if let scannerError = error as? ScannerError {
            switch scannerError {
            case .cameraAccessDenied:
                errorMessage = "Camera access is denied. Please allow access in Settings."
            case .scanFailed:
                errorMessage = "Failed to scan the document. Please try again."
            case .unknownError:
                errorMessage = "An unknown error occurred. Please try again."
            }
        } else {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        // Present an alert or some form of UI feedback
        showAlert(with: errorMessage)
    }
    
    func showAlert(with message: String) {
        // Add your alert presentation logic, e.g., using SwiftUI's `Alert`
        alertMessage = message
        showAlert = true
    }
}
