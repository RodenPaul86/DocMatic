//
//  Home.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI
import SwiftData
import VisionKit
import TipKit

struct Home: View {
    /// View Properties
    @State private var showScannerView: Bool = false
    @State private var scanDocument: VNDocumentCameraScan?
    @State private var searchText = "" /// <- Holds the search input
    @State private var documentName: String = "New Document"
    @State private var askDocumentName: Bool = false
    @State private var isLoading: Bool = false
    @State private var isSettingsOpen: Bool = false
    @Query(sort: [.init(\Document.createdAt, order: .reverse)], animation: .snappy(duration: 0.25)) private var documents: [Document]
    
    /// Environment Values
    @Namespace private var animationID
    @Environment(\.modelContext) private var context
    
    /// Filtered documents based on search text
    var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return documents
        } else {
            return documents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                // Use adaptive grid with dynamic number of columns based on device size
                let columns = [GridItem(.adaptive(minimum: 150, maximum: 300))]
                
                if filteredDocuments.isEmpty {
                    // Display a message when there are no documents
                    Text("No documents available")
                        .font(.title3.italic())
                        .foregroundColor(.gray)
                        .padding()
                    
                } else {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(filteredDocuments) { document in
                            NavigationLink {
                                DocumentDetailView(document: document)
                                    .navigationTransition(.zoom(sourceID: document.uniqueViewID, in: animationID))
                            } label: {
                                DocumentCardView(document: document, animationID: animationID)
                                    .foregroundStyle(Color.primary)
                            }
                            .onAppear {
                                Task { await ClosingTheView.setClosingEvent.donate() }
                            }
                        }
                    }
                    .padding(15)
                }
            }
            .navigationTitle("My Documents")
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        
                    }) {
                        HStack {
                            Image(systemName: "heart")
                            Text("Donate")
                        }
                        .foregroundStyle(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .foregroundStyle(.purple.gradient)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                CreateButton()
            }
        }
        .fullScreenCover(isPresented: $showScannerView) {
            ScannerView { error in
                // Handle errors here
            } didCancel: {
                showScannerView = false
            } didFinish: { scan in
                scanDocument = scan
                showScannerView = false
                askDocumentName = true
            }
            .ignoresSafeArea()
        }
        .alert("Document Name", isPresented: $askDocumentName) {
            TextField("New Document", text: $documentName)
            Button("Save") { createDocument() }
                .disabled(documentName.isEmpty)
        }
        .loadingScreen(status: $isLoading)
    }
    
    /// Custom Scan Document Button
    @ViewBuilder
    private func CreateButton() -> some View {
        Button {
            showScannerView.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "document.viewfinder.fill")
                    .font(.title3)
                
                Text("Scan Documents")
            }
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(.purple.gradient, in: .capsule)
        }
        .hSpacing(.center)
        .padding(.vertical, 10)
        .background {
            Rectangle()
                .fill(.background)
                .mask {
                    Rectangle()
                        .fill(.linearGradient(colors: [
                            .white.opacity(0),
                            .white.opacity(0.5),
                            .white,
                            .white
                        ], startPoint: .top, endPoint: .bottom))
                }
                .ignoresSafeArea()
        }
    }
    
    /// Helper Methods
    private func createDocument() {
        guard let scanDocument else { return }
        isLoading = true
        Task.detached(priority: .high) { [documentName] in
            let document = Document(name: documentName)
            var pages: [DocumentPage] = []
            
            for pageIndex in 0..<scanDocument.pageCount {
                let pageImage = scanDocument.imageOfPage(at: pageIndex)
                guard let pageData = pageImage.jpegData(compressionQuality: 0.65) else { return }
                let documentPage = DocumentPage(document: document, pageIndex: pageIndex, pageData: pageData)
                pages.append(documentPage)
            }
            document.pages = pages
            
            await MainActor.run {
                context.insert(document)
                try? context.save()
                
                self.scanDocument = nil
                isLoading = false
                self.documentName = "New Document"
            }
        }
    }
}

#Preview {
    SchemeHostView {
        ContentView()
    }
}
