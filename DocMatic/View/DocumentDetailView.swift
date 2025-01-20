//
//  DocumentDetailView.swift
//  DocMatic
//
//  Created by Paul  on 1/18/25.
//

import SwiftUI
import PDFKit
import LocalAuthentication

struct DocumentDetailView: View {
    var document: Document
    
    /// View Properties
    @State private var isLoading: Bool = false
    @State private var showFileMover: Bool = false
    @State private var fileURL: URL?
    
    @State private var deleteAlert: Bool = false
    
    /// Lock Screen Properties
    @State private var isLockAvailable: Bool?
    @State private var isUnlocked: Bool = false
    
    /// Renaming Properties
    @State private var isRenaming: Bool = false
    @State private var newFileName: String = ""
    
    /// Environment Values
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scene
    
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
                        }
                    }
                }
                .tabViewStyle(.page)
                
                /// Footer View
                //FooterView()
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
            .font(.callout)
            .foregroundStyle(.white)
            .hSpacing(.center)
            .overlay(alignment: .trailing) {
                /// Close Button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.title3.bold())
                        .foregroundStyle(.purple.gradient)
                }
            }
            .overlay(alignment: .leading) {
                Menu {
                    /// Share Document
                    Button(action: { shareDocument() }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    /// Save Document
                    Button(action: { createAndShareDocument() }) {
                        Label("Save to Files", systemImage: "folder")
                    }
                    
                    /// Print File
                    Button(action: { printDocument() }) {
                        Label("Print", systemImage: "printer")
                    }
                    
                    /// Rename File
                    Button(action: {
                        newFileName = document.name // Pre-fill the current name
                        isRenaming = true
                    }) {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    /// Lock File
                    Button(action: {
                        document.isLocked.toggle()
                        isUnlocked = !document.isLocked
                        try? context.save()
                    }) {
                        Label(document.isLocked ? "Unlock" : "Lock", systemImage: document.isLocked ? "lock.fill" : "lock.open.fill")
                    }
                    
                    /// Delete File
                    Button(role: .destructive) { deleteAlert = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.purple.gradient)
                }
                .alert("Are you sure you want to delete this document?", isPresented: $deleteAlert) {
                    Button("Delete", role: .destructive) {
                        dismiss()
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.3))
                            context.delete(document)
                            try? context.save()
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        // Alert dismisses automatically
                    }
                }
                .alert("Rename Document", isPresented: $isRenaming) {
                    TextField("New File Name", text: $newFileName)
                    Button("Save", action: renameFile)
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Enter a new name for your file.")
                }
            }
    }
    
    @ViewBuilder
    private func FooterView() -> some View {
        HStack {
            /// Share Button
            Button(action: createAndShareDocument) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.title3)
                    .foregroundStyle(.purple)
            }
            
            Spacer(minLength: 0)
            
            Button {
                deleteAlert = true
            } label: {
                Image(systemName: "trash.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
            .alert("Are you sure you want to delete this?", isPresented: $deleteAlert) {
                Button("Delete", role: .destructive) {
                    dismiss()
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.3))
                        context.delete(document)
                        try? context.save()
                    }
                }
                Button("Cancel", role: .cancel) {
                    // Alert dismisses automatically
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
        
        window.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }
}
