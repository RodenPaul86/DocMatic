//
//  ContentView.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI
import VisionKit
import WidgetKit
import PDFKit
import SwiftData

enum ScannerError: Error {
    case cameraAccessDenied
    case scanFailed
    case unknownError
}

struct ContentView: View {
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @State private var showScannerView: Bool = false
    @State private var showImportOption: Bool = false
    @State private var showDocumentPicker = false
    @State private var isPaywallPresented: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var scanDocument: VNDocumentCameraScan?
    @State private var askDocumentName: Bool = false
    @State private var isLoading: Bool = false
    @State private var documentName: String = "New Document"
    @State private var isFreeLimitAlert: Bool = false
    @Environment(\.modelContext) private var context
    @Environment(\.requestReview) var requestReview
    @EnvironmentObject var tabBarVisibility: TabBarVisibility
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var selectedTab = "Home"
    @State private var isKeyboardVisible: Bool = false
    
    var body: some View {
        ZStack {
            Group {
                switch selectedTab {
                case "Home":
                    HomeView()
                case "Settings":
                    SettingsView()
                default:
                    HomeView()
                }
            }
            
            VStack {
                Spacer()
                
                if tabBarVisibility.isVisible {
                    GlassTabBar(selectedTab: $selectedTab) {
                        if appSubModel.isSubscriptionActive {
                            showImportOption = true
                        } else if ScanManager.shared.scansLeft > 0 {
                            showScannerView = true
                        } else {
                            isPaywallPresented = true
                        }
                        if isHapticsEnabled {
                            hapticManager.shared.notify(.notification(.success))
                        }
                    }
                    .padding(.bottom, -10)
                    .background {
                        progressiveBlurView()
                            .blur(radius: 10)
                            .padding(.horizontal, -15)
                            .padding(.bottom, -120)
                            .padding(.top, -10)
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        )
                    )
                    
                    if !appSubModel.isSubscriptionActive {
                        adBannerView()
                            .padding(.top, 10)
                    }
                }
            }
            .confirmationDialog("Choose how you’d like to add a document.", isPresented: $showImportOption, titleVisibility: .visible) {
                Button("Scan") {
                    showScannerView = true
                }
                
                Button("Import") {
                    showDocumentPicker = true
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker { urls in
                    // Handle imported document URLs here
                    for url in urls {
                        Task {
                            await saveImportedDocument(from: url, in: context)
                        }
                    }
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
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                DispatchQueue.main.async {
                    tabBarVisibility.isVisible = false
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                DispatchQueue.main.async {
                    tabBarVisibility.isVisible = true
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
        .onOpenURL { url in
            if url.scheme == "docmatic", url.host == "scan" {
                showScannerView = true
            }
        }
        .alert("Document Name", isPresented: $askDocumentName) {
            TextField("New Document", text: $documentName)
            Button("Save") {
                if appSubModel.isSubscriptionActive || ScanManager.shared.scansLeft > 0 {
                    createDocument()
                } else {
                    isFreeLimitAlert = true
                }
            }
            .disabled(documentName.isEmpty)
        }
        .loadingScreen(status: $isLoading)
        .alert("Upgrade to DocMatic Pro", isPresented: $isFreeLimitAlert) {
            Button("Upgrade", role: .none) {
                isPaywallPresented = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Hmm, it appears you’ve reached your limit of 3 document scans. But don’t worry, you can unlock unlimited scans with DocMatic Pro!")
        }
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
                let originalImage = scanDocument.imageOfPage(at: pageIndex)
                
                let finalImage: UIImage
                if await appSubModel.isSubscriptionActive {
                    finalImage = originalImage
                } else {
                    let isDark = await isDarkBackground(in: originalImage)
                    let watermarkColor: UIColor = isDark
                    ? UIColor.white.withAlphaComponent(0.15)
                    : UIColor.black.withAlphaComponent(0.15)
                    
                    if let logoImage = UIImage(named: "") {
                        finalImage = await addTiledWatermarkWithLogo(
                            to: originalImage,
                            text: Bundle.main.appName,
                            logo: logoImage,
                            color: watermarkColor
                        )
                    } else {
                        finalImage = await addTiledWatermark(
                            to: originalImage,
                            text: Bundle.main.appName,
                            color: watermarkColor
                        )
                    }
                }
                
                // Save page image data
                guard let pageData = finalImage.jpegData(compressionQuality: 0.65) else { return }
                
                let fileName = "\(documentName).pdf"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                
                let pdfDocument = PDFDocument()
                
                // Insert the scanned image as a real PDF page
                if let pdfPage = PDFPage(image: finalImage) {
                    pdfDocument.insert(pdfPage, at: 0) // or insert at current page count if multiple pages
                }
                
                do {
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                    pdfDocument.write(to: tempURL)
                    
                    // Now copy to persistent location
                    let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let destination = docsURL.appendingPathComponent(fileName)
                    
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    try FileManager.default.copyItem(at: tempURL, to: destination)
                    
                    print("✅ Real PDF saved at: \(destination.path)")
                    
                } catch {
                    print("❌ Error saving real PDF: \(error)")
                    return
                }
                
                let documentPage = DocumentPage(document: document, pageIndex: pageIndex, pageData: pageData)
                pages.append(documentPage)
            }
            
            document.pages = pages
            
            await MainActor.run {
                WidgetCenter.shared.reloadAllTimelines()
                
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
        
        // MARK: Present an alert or some form of UI feedback
        showAlert(with: errorMessage)
    }
    
    func showAlert(with message: String) {
        // MARK: Add your alert presentation logic, e.g., using SwiftUI's `Alert`
        alertMessage = message
        showAlert = true
    }
    
    func addTiledWatermarkWithLogo(to image: UIImage, text: String = "DocMatic", logo: UIImage, color: UIColor) -> UIImage {
        let scale = image.scale
        let size = image.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        let fontSize = size.width * 0.035
        let spacing: CGFloat = 10
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: color
        ]
        
        let textSize = (text as NSString).size(withAttributes: attributes)
        let logoSize = CGSize(width: fontSize, height: fontSize)
        
        let watermarkWidth = logoSize.width + spacing + textSize.width
        let watermarkHeight = max(logoSize.height, textSize.height)
        
        let spacingX = watermarkWidth * 2
        let spacingY = watermarkHeight * 2
        
        for (rowIndex, y) in stride(from: 0.0, to: size.height, by: spacingY).enumerated() {
            let xOffset = (rowIndex % 2 == 0) ? 0.0 : spacingX / 2
            for x in stride(from: 0.0, to: size.width, by: spacingX) {
                let adjustedX = x + xOffset
                let origin = CGPoint(x: adjustedX, y: y)
                
                // Save current context state
                context?.saveGState()
                
                // Move the origin and apply rotation
                context?.translateBy(x: origin.x, y: origin.y)
                context?.rotate(by: .pi / 4) // 45 degrees in radians
                
                // Draw logo at (0, 0) in rotated space
                let logoRect = CGRect(origin: .zero, size: logoSize)
                logo.draw(in: logoRect, blendMode: .normal, alpha: color.cgColor.alpha)
                
                // Draw text next to logo
                let textOrigin = CGPoint(x: logoSize.width + spacing, y: 0)
                (text as NSString).draw(at: textOrigin, withAttributes: attributes)
                
                // Restore context
                context?.restoreGState()
            }
        }
        
        context?.restoreGState()
        
        let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return watermarkedImage ?? image
    }
    
    func addTiledWatermark(to image: UIImage, text: String = "DocMatic", color: UIColor) -> UIImage {
        let scale = image.scale
        let size = image.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        let fontSize = size.width * 0.05
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: color
        ]
        
        let textSize = (text as NSString).size(withAttributes: attributes)
        
        let spacingX = textSize.width * 2
        let spacingY = textSize.height * 2
        
        for (rowIndex, y) in stride(from: 0.0, to: size.height, by: spacingY).enumerated() {
            let xOffset = (rowIndex % 2 == 0) ? 0.0 : spacingX / 2
            for x in stride(from: 0.0, to: size.width, by: spacingX) {
                let adjustedX = x + xOffset
                let origin = CGPoint(x: adjustedX, y: y)
                
                // Save current context state
                context?.saveGState()
                
                // Move the origin and apply rotation
                context?.translateBy(x: origin.x, y: origin.y)
                context?.rotate(by: .pi / 4) // 45 degrees
                
                // Draw just the text
                (text as NSString).draw(at: .zero, withAttributes: attributes)
                
                // Restore context
                context?.restoreGState()
            }
        }
        
        context?.restoreGState()
        
        let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return watermarkedImage ?? image
    }
    
    func isDarkBackground(in image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        let width = cgImage.width
        let height = cgImage.height
        let center = CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 2)
        
        guard let cropped = cgImage.cropping(to: center) else { return false }
        
        let context = CIContext()
        let inputImage = CIImage(cgImage: cropped)
        let extent = inputImage.extent
        let avgFilter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: inputImage,
            kCIInputExtentKey: CIVector(cgRect: extent)
        ])!
        
        guard let outputImage = avgFilter.outputImage else { return false }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        
        let r = CGFloat(bitmap[0]) / 255.0
        let g = CGFloat(bitmap[1]) / 255.0
        let b = CGFloat(bitmap[2]) / 255.0
        
        // Use luminance formula
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance < 0.5 // true = dark background
    }
    
    func saveImportedDocument(from url: URL, in context: ModelContext) async {
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Failed to access security scoped resource")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let document = PDFDocument(url: url) else {
            print("❌ Failed to load PDF")
            return
        }
        
        let docName = url.deletingPathExtension().lastPathComponent
        let newDoc = Document(name: docName)
        var pages: [DocumentPage] = []
        
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            
            let pageBounds = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageBounds.size)
            
            let img = renderer.image { ctx in
                let cgContext = ctx.cgContext
                
                UIColor.white.set()
                cgContext.fill(pageBounds)
                
                // Flip the context vertically
                cgContext.saveGState()
                cgContext.translateBy(x: 0, y: pageBounds.height)
                cgContext.scaleBy(x: 1, y: -1)
                
                page.draw(with: .mediaBox, to: cgContext)
                
                cgContext.restoreGState()
            }
            
            if let data = img.jpegData(compressionQuality: 0.9) {
                let docPage = DocumentPage(document: newDoc, pageIndex: i, pageData: data)
                pages.append(docPage)
            }
        }
        
        newDoc.pages = pages
        context.insert(newDoc)
        
        do {
            try context.save()
            print("✅ Document saved successfully")
        } catch {
            print("❌ Failed to save document: \(error)")
        }
    }
}
