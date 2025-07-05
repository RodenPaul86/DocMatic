//
//  NewHome.swift
//  DocMatic
//
//  Created by Paul  on 6/11/25.
//

import SwiftUI
import SwiftData
import TipKit
import Speech
import AVFoundation
import UniformTypeIdentifiers
import PDFKit
import WidgetKit

struct HomeView: View {
    // MARK: View Properties
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) var requestReview
    
    @State private var selectedDocument: Document? = nil
    @State private var searchText: String = ""
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var progress: CGFloat = 0
    @State private var isPaywallPresented: Bool = false
    @State private var isFreeLimitAlert: Bool = false
    @State private var isSettingsOpen: Bool = false
    @State private var isTargeted: Bool = false
    @State private var isProfileShowing: Bool = false
    
    @FocusState private var isFocused: Bool
    @Query(sort: [.init(\Document.createdAt, order: .reverse)], animation: .snappy(duration: 0.25)) private var documents: [Document]
    @Namespace private var animationID
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @EnvironmentObject var tabBarVisibility: TabBarVisibility
    @EnvironmentObject var viewModel: AuthViewModel
    
    // MARK: Filtered documents based on search text
    var filteredDocuments: [Document] {
        guard !searchText.isEmpty else { return documents }
        return documents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if filteredDocuments.isEmpty {
                    if searchText.isEmpty {
                        VStack(spacing: 10) {
                            lottieView(name: "FallingDocs")
                                .frame(width: 120, height: 120)
                                .clipped()
                            
                            Text("No Documents Yet!")
                                .font(.title3.bold())
                                .foregroundStyle(.gray)
                            
                            Text(appSubModel.isSubscriptionActive ? "Your first document is just a tap away. \nYou can also drag and drop PDF's \ndirectly into the app." : "Enjoy 3 free scans to get you started! \n Need more? Unlock Pro.")
                                .font(.body)
                                .foregroundStyle(.gray.opacity(0.5))
                        }
                        .multilineTextAlignment(.center)
                        .padding()
                        
                    } else {
                        VStack(spacing: 16) {
                            lottieView(name: "MagnifyResult")
                                .frame(width: 120, height: 120)
                                .clipped()
                                .padding(0)
                            
                            Text("No Results for \"\(searchText)\"")
                                .font(.title3.bold())
                                .foregroundStyle(.gray)
                            
                            Text("Check the spelling or try a new search.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.gray.opacity(0.5))
                                .padding(.horizontal)
                        }
                        .multilineTextAlignment(.center)
                        .padding()
                    }
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    let columns = [GridItem(.adaptive(minimum: 150, maximum: 300))] /// <-- Adaptive grid with dynamic number of columns
                    
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(filteredDocuments) { document in
                            NavigationLink {
                                DocumentDetailView(document: document)
                                    .navigationTransition(.zoom(sourceID: document.uniqueViewID, in: animationID))
                            } label: {
                                DocumentCardView(document: document, animationID: animationID)
                                    .foregroundStyle(Color.primary)
                                    .onDrag {
                                        if !document.isLocked, let url = documentURL(for: document) {
                                            return NSItemProvider(contentsOf: url)!
                                        }
                                        return NSItemProvider()
                                    }
                            }
                        }
                    }
                    .padding(15)
                    .offset(y: isFocused ? 0 : progress * 75)
                    .padding(.bottom, appSubModel.isSubscriptionActive ? 80 : 100) /// <-- This is for the TabBar
                    .safeAreaInset(edge: .top, spacing: 0) {
                        resizableHeader()
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(customScrollTarget())
                .animation(.snappy(duration: 0.3, extraBounce: 0), value: isFocused)
                .onScrollGeometryChange(for: CGFloat.self) {
                    $0.contentOffset.y + $0.contentInsets.top
                } action: { oldValue, newValue in
                    //print("Scroll Offset:", newValue)
                    progress = max(min(-newValue / 75, 1), 0)
                }
            }
            .onDrop(of: [UTType.pdf.identifier], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
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
                return true
            }
            .alert("Upgrade to DocMatic Pro", isPresented: $isFreeLimitAlert) {
                Button("Upgrade", role: .none) {
                    isPaywallPresented = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Hmm, it appears you’ve reached your limit of 3 document imports. But don’t worry, you can unlock unlimited imports with DocMatic Pro!")
            }
            .fullScreenCover(isPresented: $isPaywallPresented) {
                SubscriptionView(isPaywallPresented: $isPaywallPresented)
                    .preferredColorScheme(.dark)
            }
        }
        .sheet(isPresented: $isSettingsOpen) {
            SettingsView()
        }
    }
    
    // MARK: Custom Header view
    @ViewBuilder
    func resizableHeader() -> some View {
        let progress = isFocused ? 1.0 : progress
        
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date().formatted(date: .long, time: .omitted))
                        .font(.callout)
                        .foregroundStyle(.gray)
                    
                    if let user = viewModel.currentUser {
                        let firstName = user.fullname.split(separator: " ").first.map(String.init) ?? user.fullname
                        Text("Welcome, \(firstName)")
                            .font(.title.bold())
                    } else {
                        Text("Welcome, Guest")
                            .font(.title.bold())
                    }
                }
                
                Spacer(minLength: 0)
                
                // MARK: Profile Picture
                Button(action: {
                    isProfileShowing = true
                    if isHapticsEnabled {
                        hapticManager.shared.notify(.impact(.light))
                    }
                }) {
                    Image(systemName: "person.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(.circle)
                }
                
                // MARK: App Scheme and Settings for iPad
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Button(action: { showPickerView.toggle() }) {
                        Image(systemName: appScheme == .dark ? "sun.max.circle" : "moon.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(.circle)
                    }
                    
                    Button(action: { isSettingsOpen.toggle() }) {
                        Image(systemName: "gear.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(.circle)
                    }
                }
            }
            .frame(height: 60 - (60 * progress), alignment: .bottom)
            .padding(.horizontal, 15)
            .padding(.top, 15)
            .padding(.bottom, 15 - (15 * progress))
            .opacity(1 - progress)
            .offset(y: -10 * progress)
            
            // MARK: Floating Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)
                
                TextField(speechRecognizer.isListening ? "Listening..." : "Search", text: $searchText)
                    .focused($isFocused)
                    .onChange(of: isFocused) { oldValue, newValue in
                        withAnimation {
                            tabBarVisibility.isVisible = !newValue
                        }
                    }
                
                // MARK: Right Side Controls
                if speechRecognizer.isListening {
                    Button(action: {
                        if isHapticsEnabled {
                            hapticManager.shared.notify(.impact(.medium))
                        }
                        if speechRecognizer.isListening {
                            speechRecognizer.stopTranscribing()
                            searchText = ""
                        } else {
                            speechRecognizer.startTranscribing { result in
                                searchText = result
                            }
                        }
                    }) {
                        Image(systemName: !speechRecognizer.isAuthorized ? "microphone.slash.fill" :
                                (speechRecognizer.isListening ? "waveform" : "microphone.fill"))
                        .symbolEffect(.variableColor.iterative, options: .repeat(.continuous))
                        .foregroundStyle(!speechRecognizer.isAuthorized ? .gray :
                                            (speechRecognizer.isListening ? .red : .gray))
                    }
                    .disabled(!speechRecognizer.isAuthorized)
                    .opacity(isFocused ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: speechRecognizer.isListening)
                    
                } else {
                    if isFocused && !searchText.isEmpty {
                        // Show clear in place of mic
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                        }
                        .transition(.opacity)
                        
                    } else {
                        // MARK: Microphone Button
                        Button(action: {
                            if speechRecognizer.isListening {
                                speechRecognizer.stopTranscribing()
                            } else {
                                speechRecognizer.startTranscribing { result in
                                    searchText = result
                                }
                            }
                        }) {
                            Image(systemName: !speechRecognizer.isAuthorized ? "microphone.slash.fill" :
                                    (speechRecognizer.isListening ? "waveform" : "microphone.fill"))
                            .foregroundStyle(!speechRecognizer.isAuthorized ? .gray :
                                                (speechRecognizer.isListening ? .red : .gray))
                        }
                        .disabled(!speechRecognizer.isAuthorized)
                        .opacity(isFocused ? 0 : 1)
                        .animation(.easeInOut(duration: 0.2), value: speechRecognizer.isListening)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .background {
                RoundedRectangle(cornerRadius: isFocused ? 0 : 30)
                    .fill(.background
                        .shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 5, y: 5))
                        .shadow(.drop(color: .black.opacity(0.05), radius: 5, x: -5, y: -5))
                    )
                    .padding(.top, isFocused ? -100 : 0)
            }
            .padding(.horizontal, isFocused ? 0 : 15)
            .padding(.bottom, 10)
            .padding(.top, 5)
        }
        .onAppear {
            speechRecognizer.requestPermission()
        }
        .background {
            progressiveBlurView()
                .blur(radius: isFocused ? 0 : 10)
                .padding(.horizontal, -15)
                .padding(.bottom, -10)
                .padding(.top, -100)
        }
        .visualEffect { content, proxy in
            content
                .offset(y: offsetY(proxy))
        }
        .fullScreenCover(isPresented: $isProfileShowing) {
            if viewModel.userSession != nil {
                ProfileView()
            } else {
                LoginView()
            }
        }
    }
    
    nonisolated private
    func offsetY(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        return minY > 0 ? (isFocused ? -minY : 0) : -minY
    }
}

struct customScrollTarget: ScrollTargetBehavior {
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let endPoint = target.rect.minY
        
        if endPoint < 75 {
            if endPoint > 40 {
                target.rect.origin = .init(x: 0, y: 75)
            } else {
                target.rect.origin = .zero
            }
        }
    }
}

#Preview {
    HomeView()
}

extension HomeView {
    // MARK: drag and drop helper
    private func handleDrop(providers: [NSItemProvider]) {
        if appSubModel.isSubscriptionActive || ScanManager.shared.scansLeft > 0 {
            for provider in providers {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.pdf.identifier) { tempURL, error in
                    guard let tempURL = tempURL else {
                        print("Drop failed: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    let name = tempURL.deletingPathExtension().lastPathComponent
                    let safeName = uniqueFileName(for: name)
                    let destination = getDocumentsDirectory().appendingPathComponent("\(safeName).pdf")
                    
                    do {
                        if FileManager.default.fileExists(atPath: destination.path) {
                            try FileManager.default.removeItem(at: destination)
                        }
                        try FileManager.default.copyItem(at: tempURL, to: destination)
                        
                        DispatchQueue.main.async {
                            let newDocument = Document(name: safeName)
                            
                            if let pageImages = extractImagesFromPDF(at: destination) {
                                var pages: [DocumentPage] = []
                                
                                for (index, image) in pageImages.enumerated() {
                                    if let data = image.jpegData(compressionQuality: 0.8) {
                                        let page = DocumentPage(document: newDocument, pageIndex: index, pageData: data)
                                        pages.append(page)
                                    }
                                }
                                newDocument.pages = pages
                            }
                            modelContext.insert(newDocument)
                            ScanManager.shared.incrementScanCount()
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    } catch {
                        print("PDF import failed: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            isFreeLimitAlert = true
        }
    }
    
    // MARK: - PDF to Image Rendering
    private func extractImagesFromPDF(at url: URL) -> [UIImage]? {
        guard let pdf = CGPDFDocument(url as CFURL) else { return nil }
        var images: [UIImage] = []
        
        for pageNumber in 1...pdf.numberOfPages {
            guard let page = pdf.page(at: pageNumber) else { continue }
            
            let pageRect = page.getBoxRect(.mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                
                ctx.cgContext.translateBy(x: 0, y: pageRect.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                
                ctx.cgContext.drawPDFPage(page)
            }
            
            images.append(image)
        }
        return images
    }
    
    // MARK: - Utilities
    private func documentURL(for document: Document) -> URL? {
        let filename = "\(document.name).pdf"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func uniqueFileName(for name: String) -> String {
        var finalName = name
        var counter = 1
        while FileManager.default.fileExists(atPath: getDocumentsDirectory().appendingPathComponent("\(finalName).pdf").path) {
            finalName = "\(name)-\(counter)"
            counter += 1
        }
        return finalName
    }
}
