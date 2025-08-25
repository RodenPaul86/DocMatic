//
//  DocumentDetailView.swift
//  DocMatic
//
//  Created by Paul  on 1/18/25.
//

import SwiftUI
import PDFKit
import LocalAuthentication
import TipKit
import WidgetKit
import AVFoundation
import Vision
import VisionKit

class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var didFinishUtterance: (() -> Void)?
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        didFinishUtterance?()
    }
}

struct DocumentDetailView: View {
    var document: Document
    @State private var currentPageIndex: Int = 0
    @State private var showPageNumber: Bool = true
    
    // MARK: View Properties
    @State private var isLoading: Bool = false
    @State private var showFileMover: Bool = false
    @State private var fileURL: URL?
    
    @State private var deleteAlert: Bool = false
    
    @State private var shareButtonFrame: CGRect = .zero
    
    // MARK: Lock Screen Properties
    @State private var isLockAvailable: Bool?
    @State private var isUnlocked: Bool = false
    
    // MARK: Renaming Properties
    @State private var isRenaming: Bool = false
    @State private var newFileName: String = ""
    
    // MARK: Zooming Properties
    @State private var zoom: CGFloat = 1.0          /// <-- Current zoom level
    @State private var offset: CGSize = .zero      /// <-- Current drag offset
    @State private var lastOffset: CGSize = .zero /// <-- Previous drag offset
    @State private var isZooming: Bool = false   /// <-- Tracks if zooming is active
    
    private var zoomPercentage: Int {
        Int(zoom * 100) /// <-- Converts zoom level (e.g., 1.0 = 100%) to percentage
    }
    
    // MARK: Environment Values
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scene
    @EnvironmentObject var tabBarVisibility: TabBarVisibility
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    let allinOne = AllinOne()
    
    @State private var documentSize: String? = nil
    
    @Namespace var namespace
    @State var isExpanded: Bool = false
    
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var speechDelegate = SpeechSynthesizerDelegate()
    @State private var isSpeaking: Bool = false
    @State private var summaryText: String? = nil
    @State private var isSummarizing: Bool = false
    @State private var showSummary: Bool = false
    
    var body: some View {
        if let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) {
            ZStack {
                VStack(spacing: 10) {
                    TabView(selection: $currentPageIndex) {
                        ForEach(pages) { page in
                            if let image = UIImage(data: page.pageData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleEffect(zoom)
                                    .offset(offset) /// <-  Apply the drag offset
                                    .gesture(
                                        // MARK: Only allow dragging if zoomed in
                                        zoom > 1.0 ? DragGesture()
                                            .onChanged { value in
                                                offset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                            }
                                            .onEnded { value in
                                                lastOffset = offset
                                            } : nil /// <- Disable dragging if zoomed out
                                    )
                                    .onTapGesture { /// <-- Single-tap zoom in
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            showPageNumber.toggle()
                                            if zoom > 1.0 {
                                                zoom = 1.0
                                                offset = .zero
                                                lastOffset = .zero
                                            } else {
                                                zoom = 2.5
                                            }
                                        }
                                    }
                                    .animation(.easeInOut, value: zoom) /// <-  Smooth zooming animation
                                    .tag(page.pageIndex)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .ignoresSafeArea(edges: .bottom)
                .loadingScreen(status: $isLoading)
                .overlay {
                    if isSummarizing {
                        ZStack {
                            // Dimmed background
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                            
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text("Summarizing...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .shadow(radius: 10)
                        }
                        .transition(.opacity)
                        .animation(.easeInOut, value: isSummarizing)
                    } else {
                        LockView()
                    }
                }
                .fileMover(isPresented: $showFileMover, file: fileURL) { result in
                    if case .failure(_) = result {
                        // Removing the temp file
                        guard let fileURL else { return }
                        try? FileManager.default.removeItem(at: fileURL)
                        self.fileURL = nil
                    }
                }
                .onAppear {
                    withAnimation {
                        tabBarVisibility.isVisible = false
                    }
                    
                    if let url = generatePDFURL(from: document) {
                        documentSize = getFileSize(for: url)
                    }
                    
                    guard document.isLocked else {
                        isUnlocked = true
                        return
                    }
                    
                    let context = LAContext()
                    isLockAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
                    
                    // Setup speech synthesizer delegate
                    speechSynthesizer.delegate = speechDelegate
                    speechDelegate.didFinishUtterance = { self.isSpeaking = false }
                }
                .onDisappear {
                    withAnimation {
                        tabBarVisibility.isVisible = true
                    }
                }
                .onChange(of: scene) { oldValue, newValue in
                    if newValue != .active && document.isLocked {
                        isUnlocked = false
                    }
                }
                
                // MARK: Overlayed controls
                VStack(alignment: .leading) {
                    if isUnlocked {
                        if #available(iOS 26.0, *) {
                            if showPageNumber {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        currentPageIndex = 0
                                    }
                                }) {
                                    Text("\(currentPageIndex + 1) of \(pages.count)")
                                        .font(.callout.bold())
                                        .padding()
                                        .glassEffect(.regular.interactive(), in: .capsule)
                                        .foregroundColor(.primary)
                                        .padding()
                                }
                            }
                        } else {
                            if showPageNumber {
                                Text("\(currentPageIndex + 1) of \(pages.count)")
                                    .font(.callout.bold())
                                    .padding(8)
                                    .background(.black.opacity(0.6))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                    .padding()
                            }
                        }
                        
                        Spacer()
                        
                        FooterView() /// <-- Footer View
                            .padding(.horizontal)
                            .padding(.bottom, -13)
                            .background(Color.clear) /// <-- stays transparent
                        
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle(document.name)
            .toolbar { /// <-- Header View
                ToolbarItem(placement: .topBarLeading) {
                    if isUnlocked {
                        Menu {
                            if let documentSize {
                                Section {
                                    Label("Size: \(documentSize)", systemImage: "doc")
                                        .tint(.primary)
                                        .disabled(true)
                                }
                            }
                            
                            Section {
                                // MARK: Share Document
                                Button(action: {
                                    if let url = generatePDFURL(from: document) {
                                        let sharedPageCount = document.pages?.count ?? 1
                                        profileViewModel.addSharedPages(sharedPageCount)
                                        DocumentActionManager.shared.share(documentURL: url)
                                    }
                                    allinOne.invalidate(reason: .actionPerformed)
                                }) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                        .tint(.primary)
                                }
                                
                                // MARK: Save Document
                                Button(action: {
                                    if let url = generatePDFURL(from: document) {
                                        DocumentActionManager.shared.saveToFiles(documentURL: url)
                                    }
                                    allinOne.invalidate(reason: .actionPerformed)
                                }) {
                                    Label("Save to Files", systemImage: "folder")
                                        .tint(.primary)
                                }
                                
                                // MARK: Print File
                                Button(action: {
                                    //printDocument()
                                    if let url = generatePDFURL(from: document) {
                                        DocumentActionManager.shared.print(documentURL: url)
                                    }
                                    allinOne.invalidate(reason: .actionPerformed)
                                }) {
                                    Label("Print", systemImage: "printer")
                                        .tint(.primary)
                                }
                            }
                            
                            Section {
                                Button("Summarize", systemImage: "sparkles") {
                                    Task {
                                        isSummarizing = true
                                        defer { isSummarizing = false; showSummary = true }
                                        
                                        // OCR instead of PDFKit string extraction
                                        let text = await extractTextWithOCR(from: document)
                                        
                                        do {
                                            let client = OpenAISummarizer(apiKey: apiKeys.openAIKey)
                                            summaryText = try await client.summarizeDocument(text, targetWords: 180)
                                        } catch {
                                            summaryText = "Couldn’t summarize: \(error.localizedDescription)"
                                        }
                                    }
                                }
                                .tint(.primary)
                            }
                            
                            Section {
                                // MARK: Lock File
                                Button(action: {
                                    document.isLocked.toggle()
                                    isUnlocked = !document.isLocked
                                    try? context.save()
                                    allinOne.invalidate(reason: .actionPerformed)
                                    if document.isLocked {
                                        dismiss()
                                    }
                                    WidgetCenter.shared.reloadAllTimelines()
                                }) {
                                    Label(document.isLocked ? "Unlock" : "Lock", systemImage: document.isLocked ? "lock.open" : "lock")
                                        .tint(.primary)
                                }
                                
                                // MARK: Rename File
                                Button(action: {
                                    newFileName = document.name /// <-- Pre-fill the current name
                                    isRenaming = true
                                    allinOne.invalidate(reason: .actionPerformed)
                                }) {
                                    Label("Rename", systemImage: "pencil")
                                        .tint(.primary)
                                }
                                
                                // MARK: Delete File
                                Button(role: .destructive) {
                                    deleteAlert = true
                                    allinOne.invalidate(reason: .actionPerformed)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                        .tint(.red)
                                }
                            }
                        } label: {
                            if document.isLocked {
                                Image(systemName: "lock.fill")
                            } else {
                                Image(systemName: "ellipsis")
                            }
                        }
                        .popoverTip(allinOne)
                        .confirmationDialog("Permanently delete this document?", isPresented: $deleteAlert, titleVisibility: .visible) {
                            Button("Delete", role: .destructive) {
                                dismiss()
                                Task { @MainActor in
                                    try? await Task.sleep(for: .seconds(0.3))
                                    context.delete(document)
                                    try? context.save()
                                    ScanManager.shared.decrementScanCount()
                                    WidgetCenter.shared.reloadAllTimelines()
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                        .alert("Renaming?", isPresented: $isRenaming) {
                            TextField("New File Name", text: $newFileName)
                            Button("Save", action: renameFile)
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("Enter a new name for your document.")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showSummary) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 16) {
                        if isSummarizing {
                            ZStack {
                                ProgressView("Summarizing…")
                            }
                        } else if let summaryText {
                            ScrollView { Text(summaryText).font(.body).padding(.top, 4) }.padding()
                        } else {
                            ZStack {
                                Text("No summary available.")
                            }
                        }
                    }
                    .navigationTitle("Summary")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(isSpeaking ? "Stop" : "Read Aloud", systemImage: isSpeaking ? "stop.fill" : "speaker.wave.2.fill") {
                                if isSpeaking {
                                    speechSynthesizer.stopSpeaking(at: .immediate)
                                    isSpeaking = false
                                } else {
                                    readSummaryAloud()
                                }
                            }
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done", systemImage: "xmark") {
                                showSummary = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    struct ButtonFrameKey: PreferenceKey {
        static var defaultValue: CGRect = .zero
        static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
            value = nextValue()
        }
    }
    
    @ViewBuilder
    private func FooterView() -> some View {
        if #available(iOS 26.0, *) {
            HStack {
                Text("Zoom: \(zoomPercentage)%")
                    .font(.callout.bold())
                    .padding()
                    .glassEffect(.regular, in: .capsule)
                
                Spacer(minLength: 0)
                
                // MARK: Magnifyingglass (Plue)
                Button(action: {
                    withAnimation(.easeInOut) {
                        zoom = min(zoom + 1.0, 5.0) /// <-- Increase zoom with a maximum limit
                        showPageNumber = false
                    }
                }) {
                    Image(systemName: "plus.magnifyingglass") /// <-- Zoom-in icon
                        .font(.title)
                        .foregroundStyle(zoom < 5.0 ? Color.theme.accent.gradient : Color.gray.gradient)
                        .frame(width: 50, height: 50)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .disabled(zoom >= 5.0)
                
                // MARK: Magnifyingglass (Minus)
                if zoom > 1.0 {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            zoom = max(zoom - 0.5, 1.0) /// <-- Decrease zoom with a maximum limit
                            if zoom == 1.0 {
                                showPageNumber = true
                            }
                        }
                    }) {
                        Image(systemName: "minus.magnifyingglass") /// <-- Zoom-out icon
                            .font(.title)
                            .foregroundStyle(Color.theme.accent)
                            .frame(width: 50, height: 50)
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                }
                
                // MARK: Magnifyingglass (All the way out)
                if zoom > 1.5 {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            zoom = 1.0 /// <-- Reset zoom
                            offset = .zero /// <-- Reset drag offset
                            showPageNumber = true
                        }
                    }) {
                        Image(systemName: "arrow.up.left.and.down.right.magnifyingglass") /// <-- Zoom all the way out icon
                            .font(.title)
                            .foregroundStyle(Color.theme.accent)
                            .frame(width: 50, height: 50)
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                }
            }
        } else {
            HStack {
                Text("Zoom: \(zoomPercentage)%")
                    .font(.callout)
                    .foregroundStyle(.primary)
                
                Spacer(minLength: 0)
                
                // MARK: Magnifyingglass (Plus)
                Button(action: {
                    withAnimation(.easeInOut) {
                        zoom = min(zoom + 1.0, 5.0) /// <-- Increase zoom with a maximum limit
                    }
                }) {
                    Image(systemName: "plus.magnifyingglass") /// <-- Zoom-in icon
                        .font(.title)
                        .foregroundStyle(zoom < 5.0 ? Color.theme.accent.gradient : Color.gray.gradient)
                }
                .disabled(zoom >= 5.0)
                
                // MARK: Magnifyingglass (Minus)
                if zoom > 1.0 {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            zoom = max(zoom - 0.5, 1.0) /// <-- Decrease zoom with a maximum limit
                        }
                    }) {
                        Image(systemName: "minus.magnifyingglass") /// <-- Zoom-out icon
                            .font(.title)
                            .foregroundStyle(Color.theme.accent)
                    }
                }
                
                // MARK: Magnifyingglass (All the way out)
                if zoom > 1.5 {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            zoom = 1.0 /// <-- Reset zoom
                            offset = .zero /// <-- Reset drag offset
                        }
                    }) {
                        Image(systemName: "arrow.up.left.and.down.right.magnifyingglass") /// <-- Zoom all the way out icon
                            .font(.title)
                            .foregroundStyle(Color.theme.accent)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func LockView() -> some View {
        if document.isLocked {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                VStack(spacing: 6) {
                    if let isLockAvailable, !isLockAvailable {
                        Text("Please enable biometric access in Settings to unlock this document!")
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                    } else {
                        Image(systemName: "eye.slash")
                            .font(.largeTitle)
                        
                        Text("Tap to preview...")
                            .font(.callout)
                    }
                }
                .padding(15)
                .background(.bar, in: .rect(cornerRadius: 10))
                .contentShape(.rect)
                .onTapGesture(perform: authenticateUser)
            }
            .opacity(isUnlocked ? 0 : 1)
            .animation(snappy, value: isUnlocked)
        }
    }
    
    private func authenticateUser() {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Locked Document") { status, _ in
                DispatchQueue.main.async {
                    self.isUnlocked = status
                }
            }
        } else {
            isLockAvailable = false
            isUnlocked = false
        }
    }
    
    func generatePDFURL(from document: Document) -> URL? {
        guard let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) else { return nil }
        
        let pdfDocument = PDFDocument()
        for (index, page) in pages.enumerated() {
            if let pageImage = UIImage(data: page.pageData),
               let pdfPage = PDFPage(image: pageImage) {
                pdfDocument.insert(pdfPage, at: index)
            }
        }
        
        var tempURL = FileManager.default.temporaryDirectory
        tempURL.append(path: "\(document.name).pdf")
        
        return pdfDocument.write(to: tempURL) ? tempURL : nil
    }
    
    private func renameFile() {
        guard !newFileName.isEmpty else { return }
        document.name = newFileName
        do {
            try context.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to rename the file: \(error)")
        }
    }
    
    func getFileSize(for url: URL) -> String? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? NSNumber {
                let bytes = fileSize.doubleValue
                return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
            }
        } catch {
            print("❌ Failed to get file size: \(error)")
        }
        return nil
    }
    
    func extractTextWithOCR(from document: Document) async -> String {
        guard let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) else { return "" }
        
        var results: [String] = []
        
        for page in pages {
            if let image = UIImage(data: page.pageData)?.cgImage {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                    let observations = request.results ?? []
                    let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                    results.append(text)
                } catch {
                    print("❌ OCR failed: \(error)")
                }
            }
        }
        
        return results.joined(separator: "\n")
    }
    
    private func readSummaryAloud() {
        // Ensure delegate hookup
        speechSynthesizer.delegate = speechDelegate
        speechDelegate.didFinishUtterance = { self.isSpeaking = false }
        
        guard let text = summaryText, !text.isEmpty else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        
        speechSynthesizer.speak(utterance)
        isSpeaking = true
    }
}
