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

enum ScannerError: Error {
    case cameraAccessDenied
    case scanFailed
    case unknownError
}

struct Home: View {
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
    @Query(sort: [.init(\Document.createdAt, order: .reverse)], animation: .snappy(duration: 0.25)) private var documents: [Document]
    
    // MARK: Environment Values
    @Namespace private var animationID
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @Environment(\.modelContext) private var context
    @Environment(\.requestReview) var requestReview
    
    // MARK: Properties
    @State private var showScannerView: Bool = false
    @State private var scanDocument: VNDocumentCameraScan?
    @State private var searchText = "" /// <- Holds the search input
    @State private var documentName: String = "New Document"
    @State private var askDocumentName: Bool = false
    @State private var isLoading: Bool = false
    @State private var isSettingsOpen: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isPresentedManageSubscription = false
    @State private var isPaywallPresented: Bool = false
    
    // MARK: Filtered documents based on search text
    var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return documents
        } else {
            return documents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    let showWelcomTip = Welcome()
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                // Use adaptive grid with dynamic number of columns based on device size
                let columns = [GridItem(.adaptive(minimum: 150, maximum: 300))]
                
                TipView(showWelcomTip)
                    .padding(.horizontal)
                
                if filteredDocuments.isEmpty {
                    VStack(spacing: 20) {
                        if searchText.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "document")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 55, height: 55)
                                
                                Text("No Documents Yet!")
                                    .font(.title3.bold())
                                
                                Text(appSubModel.isSubscriptionActive ? "Your first document is just a tap away!" : "Enjoy 3 free scans to get you started! \n Need more? Unlock Pro.")
                                    .font(.body)
                                    .multilineTextAlignment(.center) /// <-- Centers long text
                            }
                            .padding(.top, 50)
                            .frame(maxWidth: .infinity) /// <-- Ensures centering horizontally
                            .foregroundStyle(.gray.opacity(0.5))
                            
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 55, height: 55)
                                    .foregroundStyle(.gray)
                                
                                Text("No Results Found")
                                    .font(.title3.bold())
                                    .foregroundStyle(.gray)
                                
                                Text("Hmm, no matches for \"\(searchText)\". Let’s try something else!")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal, 30)
                                
                                Button(action: {
                                    // MARK: Clear search
                                    searchText = ""
                                }) {
                                    Text("Clear Search")
                                        .font(.headline)
                                        .foregroundStyle(Color("Default").gradient)
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
                        }
                    }
                    .padding(15)
                }
            }
            .navigationTitle("My Documents")
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        HStack {
                            Button(action: { showPickerView.toggle() }) {
                                Image(systemName: appScheme == .dark ? "sun.max" : "moon")
                                    .foregroundStyle(Color("Default").gradient)
                            }
                            
                            Button(action: { isSettingsOpen.toggle() }) {
                                Image(systemName: "gear")
                                    .foregroundStyle(Color("Default").gradient)
                            }
                        }
                    } else {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gear")
                                .foregroundStyle(Color("Default").gradient)
                        }
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
        .sheet(isPresented: $isSettingsOpen) {
            SettingsView()
        }
    }
    
    // MARK: Custom Scan Document Button
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
            HapticManager.shared.notify(.impact(.light))
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

#Preview {
    SchemeHostView {
        ContentView()
    }
}
