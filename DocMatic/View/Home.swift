//
//  Home.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI
import SwiftData
import TipKit
import RevenueCat

struct Home: View {
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
    @Query(sort: [.init(\Document.createdAt, order: .reverse)], animation: .snappy(duration: 0.25)) private var documents: [Document]
    
    // MARK: Environment Values
    @Namespace private var animationID
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @Environment(\.modelContext) private var context
    
    // MARK: Properties
    @State private var searchText = "" /// <- Holds the search input
    @State private var isSettingsOpen: Bool = false
    
    // MARK: Filtered documents based on search text
    var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return documents
        } else {
            return documents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    let showWelcomTip = Welcome()
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                // Use adaptive grid with dynamic number of columns based on device size
                let columns = [GridItem(.adaptive(minimum: 150, maximum: 300))]
                
                TipView(showWelcomTip)
                    .padding(.horizontal)
                
                if filteredDocuments.isEmpty {
                    VStack(spacing: 20) {
                        if searchText.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "document")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 55, height: 55)
                                
                                Text("No Documents Yet!")
                                    .font(.title3.bold())
                                
                                Text(appSubModel.isSubscriptionActive ? "Your first document is just a tap away!" : "Enjoy 3 free scans to get you started! \n Need more? Unlock Pro.")
                                    .font(.body)
                                    .multilineTextAlignment(.center) /// <-- Centers long text
                            }
                            .padding(.top, 50)
                            .frame(maxWidth: .infinity) /// <-- Ensures centering horizontally
                            .foregroundStyle(.gray.opacity(0.5))
                            
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 55, height: 55)
                                    .foregroundStyle(.gray)
                                
                                Text("No Results Found")
                                    .font(.title3.bold())
                                    .foregroundStyle(.gray)
                                
                                Text("Hmm, no matches for \"\(searchText)\". Let’s try something else!")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal, 30)
                                
                                Button(action: {
                                    // MARK: Clear search
                                    searchText = ""
                                }) {
                                    Text("Clear Search")
                                        .font(.headline)
                                        .foregroundStyle(Color("Default").gradient)
                                }
                            }
                            .padding(.top, 50)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
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
                        }
                    }
                    .padding(15)
                }
            }
            .navigationTitle("My Documents")
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        HStack {
                            Button(action: { showPickerView.toggle() }) {
                                Image(systemName: appScheme == .dark ? "sun.max" : "moon")
                                    .foregroundStyle(Color("Default").gradient)
                            }
                            
                            Button(action: { isSettingsOpen.toggle() }) {
                                Image(systemName: "gear")
                                    .foregroundStyle(Color("Default").gradient)
                            }
                        }
                    } else {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gear")
                                .foregroundStyle(Color("Default").gradient)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isSettingsOpen) {
            SettingsView()
        }
    }
}

#Preview {
    SchemeHostView {
        ContentView()
    }
}
