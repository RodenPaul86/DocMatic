//
//  feedbackView.swift
//  DocMatic
//
//  Created by Paul  on 2/17/25.
//

import SwiftUI
import MessageUI
import PhotosUI

struct feedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowingMailView = false
    @State private var textBody: String = ""
    @State private var selectedTopic: String = "Feedback"
    private let topics = ["Feedback", "Question", "Request", "Bug Report", "Other"]
    
    @State private var selectedImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil
    
    var body: some View {
        NavigationStack {
            List {
                // Topic Row
                HStack {
                    Text("Topic")
                        .font(.headline)
                    Spacer()
                    
                    // Menu with Chevron
                    Menu {
                        ForEach(topics, id: \.self) { topic in
                            Button(action: {
                                selectedTopic = topic
                            }) {
                                Text(topic)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedTopic)
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right") // Chevron next to text
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // MARK: Expanding TextField
                TextField("Enter text here...", text: $textBody, axis: .vertical)
                    .padding(.vertical, 8)
                    .frame(minHeight: 120, alignment: .top) // Ensures expansion
                
                Section(header: Text("Additional Info"), footer: Text("Only upload images related to your ''\(selectedTopic)''.")) {
                    HStack {
                        // Image Preview
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .cornerRadius(10)
                        }
                        
                        // Image section
                        PhotosPicker(selection: $selectedItem, matching: .screenshots) {
                            Text("Select an image to attach...")
                        }
                        .onChange(of: selectedItem) { oldItem, newItem in
                            loadImage(from: newItem)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                    }
                }
                
                // MARK: Other sections
                Section(header: Text("Device Info")) {
                    HStack {
                        Text("Device")
                        
                        Spacer()
                        
                        Text("\(UIDevice.current.modelName)")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("\(UIDevice.current.deviceOS)")
                        
                        Spacer()
                        
                        Text("\(UIDevice.current.OSVersion)")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("App Info")) {
                    HStack {
                        Text("Name")
                        
                        Spacer()
                        
                        Text(Bundle.main.appName)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Version")
                        
                        Spacer()
                        
                        Text("\(Bundle.main.appVersion)")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Build")
                        
                        Spacer()
                        
                        Text("\(Bundle.main.appBuild)")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationBarTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingMailView.toggle()
                    }) {
                        Text("Send")
                    }
                    .sheet(isPresented: $isShowingMailView) {
                        MailView(
                            isShowing: $isShowingMailView,
                            recipient: "support@docmatic.app",
                            subject: "DocMatic: \(selectedTopic)",
                            body: generateEmailBody(),
                            imageData: imageData
                        ) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Selection Screen
    struct TopicSelectionView: View {
        @Binding var selectedTopic: String
        let topics: [String]

        var body: some View {
            List {
                ForEach(topics, id: \.self) { topic in
                    Button {
                        selectedTopic = topic
                    } label: {
                        HStack {
                            Text(topic)
                            Spacer()
                            if selectedTopic == topic {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Topic")
        }
    }
    
    private func generateEmailBody() -> String {
        return """
            <html>
                  <body style="font-family: -apple-system; font-size: 16px; color: #ffffff; background-color: #000000;">
                    <p style="margin-bottom: 20px;">\(textBody)</p><br><br><br>
            
                    <table style="border-collapse: collapse; font-size: 16px;">
                      <tr><td><strong>Device:</strong></td><td style="padding-left: 15px;">\(UIDevice.current.modelName)</td></tr>
                      <tr><td><strong>\(UIDevice.current.deviceOS):</strong></td><td style="padding-left: 15px;">\(UIDevice.current.OSVersion)</td></tr>
                      <tr><td><strong>App:</strong></td><td style="padding-left: 15px;">\(Bundle.main.appName)</td></tr>
                      <tr><td><strong>Version:</strong></td><td style="padding-left: 15px;">\(Bundle.main.appVersion)</td></tr>
                      <tr><td><strong>Build:</strong></td><td style="padding-left: 15px;">\(Bundle.main.appBuild)</td></tr>
                    </table>
                  </body>
                </html>
            """
    }
    
    // MARK: Function to load image from PhotosPicker
    private func loadImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    imageData = data
                }
            case .failure(let error):
                print("Error loading image: \(error)")
            }
        }
    }
}

#Preview {
    feedbackView()
}

// MARK: MailView Wrapper
struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    var recipient: String
    var subject: String
    var body: String
    var imageData: Data?
    var onDismiss: (() -> Void)?
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        
        init(parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
            parent.isShowing = false
            parent.onDismiss?()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.setToRecipients([recipient])
        mailComposeVC.setSubject(subject)
        mailComposeVC.setMessageBody(body, isHTML: true)
        mailComposeVC.mailComposeDelegate = context.coordinator
        
        // Attach the image if available
        if let imageData = imageData {
            mailComposeVC.addAttachmentData(imageData, mimeType: "image/jpeg", fileName: "feedback.jpg")
        }
        
        return mailComposeVC
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}
