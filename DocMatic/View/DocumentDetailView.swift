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

struct DocumentDetailView: View {
    var document: Document
    
    /// View Properties
    @State private var isLoading: Bool = false
    @State private var showFileMover: Bool = false
    @State private var fileURL: URL?
    
    @State private var deleteAlert: Bool = false
    
    @State private var shareButtonFrame: CGRect = .zero
    
    /// Lock Screen Properties
    @State private var isLockAvailable: Bool?
    @State private var isUnlocked: Bool = false
    
    /// Renaming Properties
    @State private var isRenaming: Bool = false
    @State private var newFileName: String = ""
    
    /// Zooming Properties
    @State private var zoom: CGFloat = 1.0          // Current zoom level
    @State private var offset: CGSize = .zero      // Current drag offset
    @State private var lastOffset: CGSize = .zero // Previous drag offset
    @State private var isZooming: Bool = false   // Tracks if zooming is active
    
    private var zoomPercentage: Int {
        Int(zoom * 100) // Converts zoom level (e.g., 1.0 = 100%) to percentage
    }
    
    /// Environment Values
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scene
    
    let allinOne = AllinOne()
    let closingTheView = ClosingTheView()
    
    var body: some View {
        if let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) {
            VStack(spacing: 10) {
                /// Header View
                HeaderView()
                    .padding([.horizontal, .top], 15)
                
                TabView {
                    ForEach(pages) { page in
                        if let image = UIImage(data: page.pageData) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(zoom)
                                .offset(offset) /// <-  Apply the drag offset
                                .gesture(
                                    // Only allow dragging if zoomed in
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
                                .animation(.easeInOut, value: zoom) /// <-  Smooth zooming animation
                        }
                    }
                }
                .tabViewStyle(zoom > 1.0 ? .page(indexDisplayMode: .never) : .page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                /// Footer View
                FooterView()
            }
            .background(.black)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .loadingScreen(status: $isLoading)
            .overlay {
                LockView()
            }
            .fileMover(isPresented: $showFileMover, file: fileURL) { result in
                if case .failure(_) = result {
                    /// Removing the temp file
                    guard let fileURL else { return }
                    try? FileManager.default.removeItem(at: fileURL)
                    self.fileURL = nil
                }
            }
            .onAppear {
                guard document.isLocked else {
                    isUnlocked = true
                    return
                }
                
                let context = LAContext()
                isLockAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            }
            .onChange(of: scene) { oldValue, newValue in
                if newValue != .active && document.isLocked {
                    isUnlocked = false
                }
            }
        }
    }
    
    @ViewBuilder
    private func HeaderView() -> some View {
        Label(document.name, systemImage: document.isLocked ? "lock.fill" : "")
            .font(.title3)
            .foregroundStyle(.white)
            .hSpacing(.center)
            .overlay(alignment: .trailing) {
                /// Close Button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.title3.bold())
                        .foregroundStyle(.purple)
                }
            }
            .overlay(alignment: .leading) {
                GeometryReader { geometry in
                    Menu {
                        /// Share Document
                        Button(action: {
                            shareDocument()
                            allinOne.invalidate(reason: .actionPerformed)
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        /// Save Document
                        Button(action: {
                            createAndShareDocument()
                            allinOne.invalidate(reason: .actionPerformed)
                        }) {
                            Label("Save to Files", systemImage: "folder")
                        }
                        
                        /// Print File
                        Button(action: {
                            printDocument()
                            allinOne.invalidate(reason: .actionPerformed)
                        }) {
                            Label("Print", systemImage: "printer")
                        }
                        
                        /// Rename File
                        Button(action: {
                            newFileName = document.name // Pre-fill the current name
                            isRenaming = true
                            allinOne.invalidate(reason: .actionPerformed)
                        }) {
                            Label("Rename", systemImage: "pencil")
                        }
                        
                        /// Lock File
                        Button(action: {
                            document.isLocked.toggle()
                            isUnlocked = !document.isLocked
                            try? context.save()
                            allinOne.invalidate(reason: .actionPerformed)
                        }) {
                            Label(document.isLocked ? "Unlock" : "Lock", systemImage: document.isLocked ? "lock.fill" : "lock.open.fill")
                        }
                        
                        /// Delete File
                        Button(role: .destructive) {
                            deleteAlert = true
                            allinOne.invalidate(reason: .actionPerformed)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(.purple)
                            .background(GeometryReader { buttonGeometry in
                                Color.clear.preference(key: ButtonFrameKey.self, value: buttonGeometry.frame(in: .global))
                            })
                    }
                    .popoverTip(allinOne)
                    .alert("Delete this document?", isPresented: $deleteAlert) {
                        Button("Delete", role: .destructive) {
                            dismiss()
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(0.3))
                                context.delete(document)
                                try? context.save()
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    }
                    .alert("Rename Document", isPresented: $isRenaming) {
                        TextField("New File Name", text: $newFileName)
                        Button("Save", action: renameFile)
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Enter a new name for your file.")
                    }
                }
                .onPreferenceChange(ButtonFrameKey.self) { frame in
                    shareButtonFrame = frame
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
        HStack {
            Text("Zoom: \(zoomPercentage)%")
                .font(.callout)
                .foregroundStyle(.white)
            
            Spacer(minLength: 0)
            
            // Magnifyingglass (Plus)
            Button(action: {
                withAnimation(.easeInOut) {
                    zoom = min(zoom + 0.5, 5.0) /// <- Increase zoom with a maximum limit
                }
            }) {
                Image(systemName: "plus.magnifyingglass") /// <- Zoom-in icon
                    .font(.title)
                    .foregroundStyle(zoom < 5.0 ? .purple : .gray)
            }
            .disabled(zoom >= 5.0)
            
            // Magnifyingglass (Minus)
            Button(action: {
                withAnimation(.easeInOut) {
                    zoom = max(zoom - 0.5, 1.0) /// <- Decrease zoom with a maximum limit
                }
            }) {
                Image(systemName: "minus.magnifyingglass") /// <- Zoom-out icon
                    .font(.title)
                    .foregroundStyle(zoom > 1.0 ? .purple : .gray)
            }
            .disabled(zoom <= 1.0)
            
            if zoom > 2.5 {
                // Magnifyingglass (All the way out)
                Button(action: {
                    withAnimation(.easeInOut) {
                        zoom = 1.0 /// <- Reset zoom
                        offset = .zero /// <- Reset drag offset
                    }
                }) {
                    Image(systemName: "arrow.up.left.and.down.right.magnifyingglass") /// <- Zoom all the way out icon
                        .font(.title)
                        .foregroundStyle(.purple)
                }
            }
        }
        .padding([.horizontal, .bottom], 15)
    }
    
    @ViewBuilder
    private func LockView() -> some View {
        if document.isLocked {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                VStack(alignment: .center, spacing: 6) {
                    TipView(closingTheView)
                        .padding()
                    Spacer()
                }
                
                VStack(spacing: 6) {
                    if let isLockAvailable, !isLockAvailable {
                        Text("Please enable biometric access in Settings to unlock this document!")
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.largeTitle)
                        
                        Text("Tap to unlock!")
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
    
    private func createAndShareDocument() {
        /// Converting SwiftData document into a PDF Document
        guard let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) else { return }
        isLoading = true
        
        Task.detached(priority: .high) { [document] in
            try? await Task.sleep(for: .seconds(0.2))
            
            let pdfDocument = PDFDocument()
            for index in pages.indices {
                if let pageImage = UIImage(data: pages[index].pageData),
                   let pdfPage = PDFPage(image: pageImage) {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
            
            var pdfURL = FileManager.default.temporaryDirectory
            let fileName = "\(document.name).pdf"
            pdfURL.append(path: fileName)
            
            if pdfDocument.write(to: pdfURL) {
                await MainActor.run { [pdfURL] in
                    fileURL = pdfURL
                    showFileMover = true
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                    print("Failed to write PDF document.")
                }
            }
        }
    }
    
    private func printDocument() {
        guard let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) else { return }
        
        // Create a PDF Document
        let pdfDocument = PDFDocument()
        for (index, page) in pages.enumerated() {
            if let pageImage = UIImage(data: page.pageData),
               let pdfPage = PDFPage(image: pageImage) {
                pdfDocument.insert(pdfPage, at: index)
            }
        }
        
        // Write PDF to a temporary file
        var tempURL = FileManager.default.temporaryDirectory
        tempURL.append(path: "\(document.name).pdf")
        
        if pdfDocument.write(to: tempURL) {
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.outputType = .general
            printInfo.jobName = document.name
            
            let printController = UIPrintInteractionController.shared
            printController.printInfo = printInfo
            printController.printingItem = tempURL
            
            // Present the print dialog
            printController.present(animated: true, completionHandler: nil)
        } else {
            print("Failed to write PDF for printing.")
        }
    }
    
    private func renameFile() {
        guard !newFileName.isEmpty else { return }
        document.name = newFileName
        do {
            try context.save()
        } catch {
            print("Failed to rename the file: \(error)")
        }
    }
    
    private func shareDocument() {
        guard let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) else { return }
        isLoading = true
        
        Task.detached(priority: .high) { [document] in
            try? await Task.sleep(for: .seconds(0.2))
            
            let pdfDocument = PDFDocument()
            for index in pages.indices {
                if let pageImage = UIImage(data: pages[index].pageData),
                   let pdfPage = PDFPage(image: pageImage) {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
            
            var pdfURL = FileManager.default.temporaryDirectory
            let fileName = "\(document.name).pdf"
            pdfURL.append(path: fileName)
            
            if pdfDocument.write(to: pdfURL) {
                await MainActor.run { [pdfURL] in
                    isLoading = false
                    presentShareSheet(for: pdfURL)
                }
            } else {
                await MainActor.run {
                    isLoading = false
                    print("Failed to write PDF document.")
                }
            }
        }
    }
    
    private func presentShareSheet(for url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [.addToReadingList, .assignToContact]
        
        // iPad popover setup
        if let popoverController = activityViewController.popoverPresentationController {
            // Set the anchor point for the popover to the "Share" button position
            popoverController.sourceView = window.rootViewController?.view
            
            // Update the sourceRect to use the actual share button's frame
            popoverController.sourceRect = shareButtonFrame // Use the button's frame to anchor the popover
            popoverController.permittedArrowDirections = .any
        }
        
        // Present the activity view controller
        window.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }
}
