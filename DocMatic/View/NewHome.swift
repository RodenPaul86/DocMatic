//
//  NewHome.swift
//  DocMatic
//
//  Created by Paul  on 6/11/25.
//

import SwiftUI
import SwiftData
import TipKit

struct NewHome: View {
    // MARK: View Properties
    @State private var selectedDocument: Document? = nil
    @State private var searchText: String = ""
    @State private var progress: CGFloat = 0
    
    @FocusState private var isFocused: Bool
    @Query(sort: [.init(\Document.createdAt, order: .reverse)], animation: .snappy(duration: 0.25)) private var documents: [Document]
    @Namespace private var animationID
    @Binding var showTabBar: Bool
    
    let showWelcomTip = Welcome()
    
    // MARK: Filtered documents based on search text
    var filteredDocuments: [Document] {
        guard !searchText.isEmpty else { return documents }
        return documents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                let columns = [GridItem(.adaptive(minimum: 150, maximum: 300))] /// <-- Adaptive grid with dynamic number of columns
                
                LazyVGrid(columns: columns, spacing: 15) {
                    TipView(showWelcomTip)
                        .frame(maxHeight: .infinity)
                    
                    ForEach(filteredDocuments) { document in
                        NavigationLink {
                            DocumentDetailView(document: document, showTabBar: $showTabBar)
                                .navigationTransition(.zoom(sourceID: document.uniqueViewID, in: animationID))
                        } label: {
                            DocumentCardView(document: document, animationID: animationID)
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
                .padding(15)
                .offset(y: isFocused ? 0 : progress * 75)
                .padding(.bottom, 75)
                .safeAreaInset(edge: .top, spacing: 15) {
                    resizableHeader()
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(customScrollTarget())
            .animation(.snappy(duration: 0.3, extraBounce: 0), value: isFocused)
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.y + $0.contentInsets.top
            } action: { oldValue, newValue in
                progress = max(min(-newValue / 75, 1), 0)
            }
        }
    }
    
    // MARK: Custom Header view
    @ViewBuilder
    func resizableHeader() -> some View {
        let progress = isFocused ? 1 : progress
        
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome Back!")
                        .font(.callout)
                        .foregroundStyle(.gray)
                    
                    Text("Guest")
                        .font(.title.bold())
                }
                
                Spacer(minLength: 0)
                
                // MARK: Profile Picture
                Button(action: {}) {
                    Image(systemName: "person.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(.circle)
                }
            }
            .frame(height: 60 - (60 * progress), alignment: .bottom)
            .padding(.horizontal, 15)
            .padding(.top, 15)
            .padding(.bottom, 15 - (15 * progress))
            .opacity(1 - progress)
            .offset(y: -10 * progress)
            
            // MARK: Floating Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)
                
                TextField("Search Documents", text: $searchText)
                    .focused($isFocused)
                    .onChange(of: isFocused) { oldValue, newValue in
                        withAnimation {
                            showTabBar = !newValue
                        }
                    }
                
                // MARK: Microphone Button
                Button(action: {}) {
                    Image(systemName: "microphone.fill")
                        .foregroundStyle(.gray)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .background {
                RoundedRectangle(cornerRadius: isFocused ? 0 : 30)
                    .fill(.background
                        .shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 5, y: 5))
                        .shadow(.drop(color: .black.opacity(0.05), radius: 5, x: -5, y: -5))
                    )
                    .padding(.top, isFocused ? -100 : 0)
            }
            .padding(.horizontal, isFocused ? 0 : 15)
            .padding(.bottom, 10)
            .padding(.top, 5)
        }
        .background {
            progressiveBlurView()
                .blur(radius: isFocused ? 0 : 10)
                .padding(.horizontal, -15)
                .padding(.bottom, -10)
                .padding(.top, -100)
        }
        .visualEffect { content, proxy in
            content
                .offset(y: offsetY(proxy))
        }
    }
    
    nonisolated private
    func offsetY(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        return minY > 0 ? (isFocused ? -minY : 0) : -minY
    }
}

struct customScrollTarget: ScrollTargetBehavior {
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let endPoint = target.rect.minY
        
        if endPoint < 75 {
            if endPoint > 40 {
                target.rect.origin = .init(x: 0, y: 75)
            } else {
                target.rect.origin = .zero
            }
        }
    }
}

#Preview {
    NewHome(showTabBar: .constant(false))
}
