//
//  PDFImportManager.swift
//  DocMatic
//
//  Created by Paul  on 7/8/25.
//

import SwiftData
import PDFKit
import UIKit

@MainActor
class PDFImportManager: ObservableObject {
    func importPDF(from url: URL, context: ModelContext) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let pdf = PDFDocument(url: url) else {
            print("Failed to load PDF")
            return
        }
        
        var pages: [DocumentPage] = []
        
        for index in 0..<pdf.pageCount {
            guard let pdfPage = pdf.page(at: index) else { continue }
            
            // Render each page as an image (use higher size for better quality)
            let thumbnail = pdfPage.thumbnail(of: CGSize(width: 1000, height: 1400), for: .mediaBox)
            
            // Convert to JPEG Data
            if let imageData = thumbnail.jpegData(compressionQuality: 0.8) {
                let page = DocumentPage(pageIndex: index, pageData: imageData)
                pages.append(page)
            }
        }
        
        // Create and insert Document
        let documentName = url.lastPathComponent.replacingOccurrences(of: ".pdf", with: "")
        let document = Document(name: documentName, pages: pages)
        
        // Set document relationship on each page
        for page in pages {
            page.document = document
        }
        
        context.insert(document)
        ScanManager.shared.documents.append(document)
        ScanManager.shared.documents = ScanManager.shared.documents
        
        print("PDF imported successfully: \(documentName)")
    }
}
