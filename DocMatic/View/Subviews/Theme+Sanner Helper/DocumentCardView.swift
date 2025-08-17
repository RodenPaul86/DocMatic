//
//  DocumentCardView.swift
//  DocMatic
//
//  Created by Paul  on 1/18/25.
//

import SwiftUI
import WidgetKit
import LocalAuthentication
import SwiftData

struct DocumentCardView: View {
    var document: Document
    var animationID: Namespace.ID /// <- For zoom transition
    
    // MARK: View Properties
    @State private var downsizedImage: UIImage?
    
    // MARK: Renaming Properties
    @Environment(\.modelContext) private var context
    @State private var isRenaming: Bool = false
    @State private var newFileName: String = ""
    
    // MARK: Deleting Properties
    @State private var deleteAlert: Bool = false
    
    // MARK: Lock Document Properties
    @State private var isUnlocked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            /// Sorting Pages
            if let firstPage = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }).first {
                GeometryReader { geometry in
                    let size = geometry.size
                    
                    if let downsizedImage {
                        Image(uiImage: downsizedImage)
                            .resizable()
                            .aspectRatio(8.5 / 11, contentMode: .fill) /// <- Letter-size aspect ratio
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 15)) /// <- Rounded corners for paper look
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1) /// <- Subtle border to mimic paper edge
                            )
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5) /// <- Enhanced shadow for paper effect
                    } else {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .task(priority: .high) {
                                /// Downsizing Image
                                guard let image = UIImage(data: firstPage.pageData) else { return }
                                let aspectSize = image.size.aspectFit(.init(width: 150, height: 150))
                                let renderer = UIGraphicsImageRenderer(size: aspectSize)
                                let resizedImage = renderer.image { context in
                                    image.draw(in: .init(origin: .zero, size: aspectSize))
                                }
                                
                                await MainActor.run {
                                    downsizedImage = resizedImage
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5) /// <- Enhanced shadow for paper effect
                    }
                    
                    if document.isLocked {
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                            
                            Image(systemName: "lock.fill")
                                .font(.largeTitle)
                        }
                    }
                }
                .aspectRatio(8.5 / 11, contentMode: .fit) /// <- Maintain letter-size aspect ratio
                .clipShape(RoundedRectangle(cornerRadius: 15)) /// <- Rounded corners for paper effect
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5) /// <- Shadow for the entire card
            }
            
            Text(document.name)
                .font(.callout)
                .lineLimit(1)
                .padding(.top, 10)
            
            Text(document.createdAt.formatted(date: .numeric, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .padding(10) /// <- Padding for a cleaner look around the content
        .onChange(of: isUnlocked) { oldValue, newValue in
            if newValue && document.isLocked {
                document.isLocked = false
                try? context.save()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .confirmationDialog("Permanently delete this document?", isPresented: $deleteAlert, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
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
        .background(
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ) /// <- Enhanced gradient for depth
                .blur(radius: 1) /// <- Subtle blur for a smoother texture
                
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1) /// <- Subtle border for a "paper edge" effect
            }
                .clipShape(RoundedRectangle(cornerRadius: 15)) /// <- Keep rounded corners for the "paper" effect
        )
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5) /// <- Paper shadow effect
        .contextMenu {
            Button(action: {
                newFileName = document.name /// <-- Pre-fill the current name
                isRenaming = true
            }) {
                Label("Rename", systemImage: "pencil")
                    .tint(.primary)
            }
            
            Button(action: {
                duplicateDocument()
            }) {
                Label("Duplicate", systemImage: "doc.on.doc")
                    .tint(.primary)
            }
            
            Button(action: {
                if document.isLocked {
                    // Attempt biometric authentication before unlocking
                    authenticateUser()
                } else {
                    // Lock the document directly
                    document.isLocked = true
                    isUnlocked = false
                    try? context.save()
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }) {
                Label(document.isLocked ? "Unlock" : "Lock", systemImage: document.isLocked ? "lock.open" : "lock")
                    .tint(.primary)
            }
            
            Button(role: .destructive, action: {
                deleteAlert = true
            }) {
                Label("Delete", systemImage: "trash")
                    .tint(.red)
            }
        }
    }
    
    // MARK: Renaming Files
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
    
    private func authenticateUser() {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Locked Document") { status, _ in
                DispatchQueue.main.async {
                    self.isUnlocked = status
                }
            }
        } else {
            isUnlocked = false
        }
    }
    
    private func duplicateDocument() {
        do {
            // 1. Fetch all document names to avoid name collision
            let existingDocs = try context.fetch(FetchDescriptor<Document>())
            let existingNames = existingDocs.map { $0.name }
            
            // 2. Generate a unique name like "My File (Copy)"
            let newName = generateDuplicateName(from: document.name, existingNames: existingNames)
            
            // 3. Clone document pages
            let copiedPages: [DocumentPage] = document.pages?.map { originalPage in
                DocumentPage(
                    pageIndex: originalPage.pageIndex,
                    pageData: originalPage.pageData
                )
            } ?? []
            
            // 4. Create the new document and reassign page ownership
            let duplicated = Document(name: newName, pages: copiedPages)
            copiedPages.forEach { $0.document = duplicated }
            
            // 5. Save to persistent context
            context.insert(duplicated)
            try context.save()
            
            // 6. ✅ Update ScanManager (for streak, count, etc.)
            ScanManager.shared.documents.append(duplicated)
            ScanManager.shared.documents = ScanManager.shared.documents // Force UI update
            
            // Optional: Widget update
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
            print("❌ Failed to duplicate document: \(error)")
        }
    }
    
    func generateDuplicateName(from original: String, existingNames: [String]) -> String {
        var newName = "\(original) (Copy)"
        var copyIndex = 2
        
        while existingNames.contains(newName) {
            newName = "\(original) (Copy \(copyIndex))"
            copyIndex += 1
        }
        return newName
    }
}
