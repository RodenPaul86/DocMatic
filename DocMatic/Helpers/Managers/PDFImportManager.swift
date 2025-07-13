//
//  PDFImportManager.swift
//  DocMatic
//
//  Created by Paul  on 7/8/25.
//

import SwiftData
import PDFKit
import UIKit
import WidgetKit

@MainActor
class PDFImportManager: ObservableObject {
    func importPDF(from url: URL, context: ModelContext) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let pdf = PDFDocument(url: url) else {
            print("❌ Failed to load PDF")
            return
        }
        
        var pages: [DocumentPage] = []
        
        for index in 0..<pdf.pageCount {
            guard let pdfPage = pdf.page(at: index) else { continue }
            
            let thumbnail = pdfPage.thumbnail(of: CGSize(width: 1000, height: 1400), for: .mediaBox)
            
            if let imageData = thumbnail.jpegData(compressionQuality: 0.8) {
                let page = DocumentPage(pageIndex: index, pageData: imageData)
                pages.append(page)
            }
        }
        
        let documentName = url.deletingPathExtension().lastPathComponent
        let document = Document(name: documentName, createdAt: Date(), pages: pages) // ✅ Add createdAt
        
        // Link pages to their parent document
        for page in pages {
            page.document = document
        }
        
        context.insert(document)
        
        do {
            try context.save()
            ScanManager.shared.documents.append(document) // ✅ Keep scan count/streak in sync
            ScanManager.shared.documents = ScanManager.shared.documents // Force view update
            WidgetCenter.shared.reloadAllTimelines() // Optional
            print("✅ PDF imported successfully: \(documentName)")
        } catch {
            print("❌ Failed to save imported document: \(error)")
        }
    }
}
