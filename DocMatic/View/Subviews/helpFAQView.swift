//
//  HelpFAQView.swift
//  TaskSync
//
//  Created by Paul  on 12/28/24.
//

import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    var isExpanded: Bool = false
}

// MARK: Data
struct helpFAQView: View {
    @StateObject private var biometricManager = BiometricManager()
    @State private var faqItems: [FAQItem] = [
        FAQItem(question: "How do I scan a document?",
                answer: "Tap the 'Scan' button on the main screen. Align the document in the camera frame, and the app will automatically detect and capture it. Once scanned, you can save, or share the document."),
        /*
         FAQItem(question: "How do I organize my scanned documents?",
         answer: "You can organize documents by creating folders. Tap 'New Folder' in the file manager, give it a name, and move your documents into the folder."),
         
         FAQItem(question: "How can I sync my documents across devices?",
         answer: "Make sure you’re signed into the same Apple ID on all your devices and iCloud is enabled. DocMatic will sync your documents automatically when connected to the internet."),
         
         FAQItem(question: "Can I edit scanned documents?",
         answer: "Yes, you can crop, rotate, and adjust the brightness or contrast of your scanned documents directly within the app."),
         */
        FAQItem(question: "Can I edit scanned documents?",
                answer: "No, currently we do not support editing scanned documents, that functionality is still in development."),
        
        FAQItem(question: "How do I share a scanned document?",
                answer: "Open the document you want to share, tap the menu button (three dots), then select the 'Share' button. Select your preferred sharing method, such as email, AirDrop, or other apps."),
        /*
         FAQItem(question: "What should I do if my scans aren't syncing?",
         answer: "Ensure your device is connected to the internet and you’re logged into the correct Apple ID. If the issue persists, try restarting the app or logging out and back in."),
         */
        FAQItem(question: "Can I lock my scanned documents?",
                answer: "Yes, you can secure your sensitive documents using biometric authentication (Touch ID / Face ID). After saving a document, tap the menu (three dots) and select the 'Lock' option."),
        
        FAQItem(question: "How do I customize the app?",
                answer: "You can personalize the app by choosing between light, dark, or automatic appearance and you can select a custom app icon. These options are available in the settings."),
        /*
         FAQItem(question: "Can I recover deleted scans?",
         answer: "Deleted scans are moved to the 'Trash' folder for 30 days. You can restore them from there or permanently delete them."),
         */
        
        FAQItem(question: "Can I recover deleted scans?",
                answer: "Currently, there is no way to recover deleted documents. Please make sure to save important documents locally to 'Files' app before deleting them from DocMatic."),
        /*
         FAQItem(question: "Is my data secure in DocMatic?",
         answer: "Absolutely. Your scans and data are securely stored in iCloud, accessible only to you through your Apple ID."),
         */
        
        FAQItem(question: "Is my data secure in DocMatic?",
                answer: "Your scanned documents are stored securely on your device. You can also save them to the 'Files' app."),
        
        FAQItem(question: "How do I request new features?",
                answer: "We’d love to hear from you! Reach out via the “Contact Support” button in Settings or email us at support@docmatic.app.")
    ]
    
    // MARK: Main View
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: Text("").font(.headline)) {
                        ForEach($faqItems) { $item in
                            FAQRow(item: $item)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .safeAreaPadding(.bottom, 60)
            }
            .navigationTitle("FAQS")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: Custom Row
struct FAQRow: View {
    @Binding var item: FAQItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    item.isExpanded.toggle()
                    HapticManager.shared.notify(.impact(.light))
                }
            }) {
                HStack {
                    Text(item.question)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: item.isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if item.isExpanded {
                Text(item.answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    helpFAQView()
}
