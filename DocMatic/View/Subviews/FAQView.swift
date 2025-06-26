//
//  FAQView.swift
//  DocMatic
//
//  Created by Paul  on 6/26/25.
//

import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FAQCategory: Identifiable {
    let id = UUID()
    let title: String
    let items: [FAQItem]
}

struct FAQView: View {
    @State private var expandedCategories: Set<UUID> = []
    
    let faqData: [FAQCategory] = [
        FAQCategory(title: "General Use", items: [
            FAQItem(question: "What is DocMatic?", answer: "DocMatic is a document scanning app that helps you digitize, organize, and secure your documents."),
            FAQItem(question: "How do I scan a documents?", answer: "Tap the '+' button on the main screen. Align your document in the camera frame, and the app will automatically detect and capture it. Once scanned, you can save or share the document."),
            FAQItem(question: "How do I share a scanned document?", answer: "Open the document, tap the menu button (three dots), then select 'Share.' Choose your preferred method, such as AirDrop, email, or another app."),
            FAQItem(question: "Can I lock my scanned documents?", answer: "Yes. After saving a document, tap the menu (three dots) and choose 'Lock.' This uses Face ID or Touch ID to secure the file."),
            FAQItem(question: "How can I improve scan quality?", answer: "Use good lighting, ensure the document is flat, and clean your camera lens."),
            FAQItem(question: "Can I scan multiple pages into one file?", answer: "Yes. After scanning the first page, tap 'Add Page' to continue scanning additional pages into the same document.")
        ]),
        
        FAQCategory(title: "Privacy & Security", items: [
            FAQItem(question: "Are my scanned docs stored securely?", answer: "Yes. All documents are stored locally on your device and are not uploaded unless you choose to share or save them externally."),
            FAQItem(question: "Can I lock my documents?", answer: "Yes. Use Face ID or Touch ID to lock and unlock your documents for added security."),
            FAQItem(question: "Is my data synced to any servers?", answer: "No. DocMatic stores data locally. Files are only uploaded if you manually save them to iCloud or share them."),
            FAQItem(question: "Can I recover deleted documents?", answer: "No. Deleted documents cannot be recovered. Be sure to save important files to the Files app before deleting them from DocMatic.")
        ]),
        
        FAQCategory(title: "Features", items: [
            FAQItem(question: "Can I rename, share, or print documents?", answer: "Yes. Tap the menu button (three dots), then choose 'Rename,' 'Share,' or 'Print.'"),
            FAQItem(question: "How do I disable the watermark on scans?", answer: "Subscribe to DocMatic Pro to remove watermarks from your scans."),
            FAQItem(question: "How do I customize the app?", answer: "You can change the app’s appearance (light, dark, or automatic) and select a custom app icon in Settings."),
            FAQItem(question: "Can I edit scanned documents?", answer: "Not yet. Editing features are in development and will be added in a future update.")
        ]),
        
        FAQCategory(title: "Compatibility & Requirements", items: [
            FAQItem(question: "Does DocMatic work offline?", answer: "Yes. All features work without an internet connection."),
            FAQItem(question: "Which iOS versions are supported?", answer: "DocMatic supports iPhone and iPad running iOS 18 or later."),
            FAQItem(question: "Can I use DocMatic on multiple devices?", answer: "Yes. You can use DocMatic on any supported device, but syncing is not currently available.")
        ]),
        
        FAQCategory(title: "In-App Purchases", items: [
            FAQItem(question: "What’s included in the free version?", answer: "You get unlimited scans, drag-and-drop for PDFs, watermark removal, and alternate app icons."),
            FAQItem(question: "How do I upgrade to DocMatic Pro?", answer: "Go to Settings and tap 'Upgrade to DocMatic Pro.'"),
            FAQItem(question: "I purchased Pro but features are locked.", answer: "Try tapping 'Restore Purchases' in Settings. If that doesn’t work, contact support.")
        ]),
        
        FAQCategory(title: "Troubleshooting", items: [
            FAQItem(question: "The camera isn’t detecting the document.", answer: "Clean the lens, ensure good lighting, or try tapping the capture button manually."),
            FAQItem(question: "Why can’t I unlock a document?", answer: "Make sure Face ID or Touch ID is enabled on your device. You can also try restarting the app or your device."),
            FAQItem(question: "The app crashed or froze. What now?", answer: "Force-close and reopen the app. If the problem continues, try reinstalling or contact support.")
        ]),
        
        FAQCategory(title: "Support", items: [
            FAQItem(question: "How do I join DocMatic Beta (TestFlight)?", answer: """
                To join the beta and try new features early:
                
                1. Tap the 'Join TestFlight (Beta)' button in Settings.
                2. The in-app browser will open. Tap 'Join' in the top right.
                3. Safari will open DocMatic’s TestFlight page.
                4. Tap 'Install' to begin testing.
                
                Make sure you have the TestFlight app installed from the App Store.
                """),
            FAQItem(question: "Where can I suggest a feature or report a bug?", answer: "Tap 'Contact Support' in Settings or email us at support@docmatic.app. We’d love your feedback!")
        ])
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(faqData) { category in
                    FAQCategoryCard(
                        category: category,
                        isExpanded: expandedCategories.contains(category.id)
                    ) {
                        if expandedCategories.contains(category.id) {
                            expandedCategories.remove(category.id)
                        } else {
                            expandedCategories.insert(category.id)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("FAQ")
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 60) /// <-- Space for the tab bar
        }
    }
}

struct FAQCategoryCard: View {
    let category: FAQCategory
    let isExpanded: Bool
    let toggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: toggle) {
                HStack {
                    Text(category.title)
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            
            if isExpanded {
                ForEach(category.items) { item in
                    FAQItemView(item: item)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
        .animation(.easeInOut, value: isExpanded)
    }
}

struct FAQItemView: View {
    let item: FAQItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(item.question)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle")
                        .foregroundColor(.accentColor)
                }
            }
            
            if isExpanded {
                Text(item.answer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    FAQView()
}
