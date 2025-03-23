//
//  Home.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI
import SwiftData
import VisionKit
import TipKit
import RevenueCat
import RevenueCatUI

enum ScannerError: Error {
    case cameraAccessDenied
    case scanFailed
    case unknownError
}

struct Home: View {
    /// View Properties
    @State private var showScannerView: Bool = false
    @State private var scanDocument: VNDocumentCameraScan?
    @State private var searchText = "" /// <- Holds the search input
    @State private var documentName: String = "New Document"
    @State private var askDocumentName: Bool = false
    @State private var isLoading: Bool = false
    @State private var isSettingsOpen: Bool = false
    @Query(sort: [.init(\Document.createdAt, order: .reverse)], animation: .snappy(duration: 0.25)) private var documents: [Document]
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var isPresentedManageSubscription = false
    
    /// Environment Values
    @Namespace private var animationID
    @Environment(\.modelContext) private var context
    
    /// Filtered documents based on search text
    var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return documents
        } else {
            return documents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @State private var isPaywallPresented: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                // Use adaptive grid with dynamic number of columns based on device size
                let columns = [GridItem(.adaptive(minimum: 150, maximum: 300))]
                
                if filteredDocuments.isEmpty {
                    VStack(spacing: 20) {
                        if searchText.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "document.viewfinder")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundStyle(.gray)
                                
                                Text("No Documents Yet")
                                    .font(.title2.bold())
                                    .foregroundStyle(.gray)
                                
                                Text(appSubModel.isSubscriptionActive ? "Your first document is just a scan away!" : "Enjoy 5 free scans to get you started! \n Need more? Unlock Pro.")
                                    .font(.body)
                                    .multilineTextAlignment(.center) /// <-- Centers long text
                                    .foregroundStyle(.gray)
                            }
                            .padding(.top, 50)
                            .frame(maxWidth: .infinity) /// <-- Ensures centering horizontally
                            
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundStyle(.gray)
                                
                                Text("No Results Found")
                                    .font(.title2.bold())
                                    .foregroundStyle(.gray)
                                
                                Text("Hmm, no matches for \"\(searchText)\". Let’s try something else!")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal, 30)
                                
                                Button(action: {
                                    // Clear search or handle action
                                    searchText = ""
                                }) {
                                    Text("Clear Search")
                                        .font(.headline)
                                        .foregroundStyle(.purple)
                                }
                            }
                            .padding(.top, 50)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                } else {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(filteredDocuments) { document in
                            NavigationLink {
                                DocumentDetailView(document: document)
                                    .navigationTransition(.zoom(sourceID: document.uniqueViewID, in: animationID))
                            } label: {
                                DocumentCardView(document: document, animationID: animationID)
                                    .foregroundStyle(Color.primary)
                            }
                            .onAppear {
                                Task { await ClosingTheView.setClosingEvent.donate() }
                            }
                        }
                    }
                    .padding(15)
                }
            }
            .navigationTitle("My Documents")
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if appSubModel.isSubscriptionActive {
                            showAlert.toggle()
                        } else {
                            isPaywallPresented = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "laurel.leading")
                            Image(systemName: "laurel.trailing")
                        }
                        .foregroundStyle(Color("Default").gradient)
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Pro Subscriber"),
                            message: Text("Thank you for your subscription! We truly appreciate your support. You can manage your subscription at anytime."),
                            primaryButton: .default(Text("Manage Subscription")) {
                                isPresentedManageSubscription = true
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .foregroundStyle(Color("Default").gradient)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                CreateButton()
            }
        }
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
        .manageSubscriptionsSheet(isPresented: $isPresentedManageSubscription)
    }
    
    /// Custom Scan Document Button
    @ViewBuilder
    private func CreateButton() -> some View {
        Button {
            if appSubModel.isSubscriptionActive {
                showScannerView.toggle()
            } else if ScanManager.shared.scansLeft > 0 {
                showScannerView.toggle()
            } else {
                isPaywallPresented = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "document.viewfinder.fill")
                    .font(.title3)
                
                Text(appSubModel.isSubscriptionActive ? "Scan Document" : "Scans Left: \(ScanManager.shared.scansLeft)")
            }
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(Color("Default").gradient, in: .capsule)
        }
        .hSpacing(.center)
        .padding(.vertical, 10)
        .background {
            Rectangle()
                .fill(.background)
                .mask {
                    Rectangle()
                        .fill(.linearGradient(colors: [
                            .white.opacity(0),
                            .white.opacity(0.5),
                            .white,
                            .white
                        ], startPoint: .top, endPoint: .bottom))
                }
                .ignoresSafeArea()
        }
    }
    
    /// Helper Methods
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
            }
        }
        ReviewManager.incrementLaunchCount()
        ReviewManager.checkMajorVersion()
    }
    
    /// Error Handling
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

#Preview {
    SchemeHostView {
        ContentView()
    }
}
