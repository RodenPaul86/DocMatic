//
//  DocumentActionManager.swift
//  DocMatic
//
//  Created by Paul  on 6/21/25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class DocumentActionManager {
    static let shared = DocumentActionManager()
    private init() {}
    
    // MARK: Share
    func share(documentURL: URL) {
        guard let rootViewController = topViewController() else { return }
        
        let activityVC = UIActivityViewController(activityItems: [documentURL], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                        y: rootViewController.view.bounds.midY,
                                        width: 0,
                                        height: 0)
            popover.permittedArrowDirections = []
        }
        rootViewController.present(activityVC, animated: true)
    }
    
    // MARK: Print
    func print(documentURL: URL) {
        guard UIPrintInteractionController.isPrintingAvailable,
              let rootViewController = topViewController() else { return }
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = documentURL.lastPathComponent
        
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.printingItem = documentURL
        printController.showsNumberOfCopies = true
        
        printController.present(from: rootViewController.view.frame, in: rootViewController.view, animated: true, completionHandler: nil)
    }
    
    // MARK: Save to Files
    func saveToFiles(documentURL: URL) {
        guard let rootViewController = topViewController() else { return }
        
        let documentPicker = UIDocumentPickerViewController(forExporting: [documentURL], asCopy: true)
        documentPicker.shouldShowFileExtensions = true
        documentPicker.modalPresentationStyle = .formSheet
        
        rootViewController.present(documentPicker, animated: true)
    }
    
    // MARK: Get Top ViewController
    private func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {
            
            if let nav = base as? UINavigationController {
                return topViewController(base: nav.visibleViewController)
                
            } else if let tab = base as? UITabBarController {
                return topViewController(base: tab.selectedViewController)
                
            } else if let presented = base?.presentedViewController {
                return topViewController(base: presented)
            }
            return base
        }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onDocumentsPicked: ([URL]) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentsPicked: onDocumentsPicked)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [.pdf, .image, .plainText, .data] // Add/remove as needed
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentsPicked: ([URL]) -> Void
        
        init(onDocumentsPicked: @escaping ([URL]) -> Void) {
            self.onDocumentsPicked = onDocumentsPicked
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onDocumentsPicked(urls)
        }
    }
}
