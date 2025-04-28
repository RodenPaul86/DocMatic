//
//  View+Extensions.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI
import TipKit

/// Useful View Extensions
extension View {
    @ViewBuilder
    func hSpacing(_ alignment: Alignment) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    func vSpacing(_ alignment: Alignment) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }
    
    /// Easy-to-use overlayed Loading Screen
    @ViewBuilder
    func loadingScreen(status: Binding<Bool>) -> some View {
        self
            .overlay {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .frame(width: 40, height: 40)
                        .background(.bar, in: .rect(cornerRadius: 10))
                }
                .opacity(status.wrappedValue ? 1 : 0)
                .allowsHitTesting(status.wrappedValue)
                .animation(snappy, value: status.wrappedValue)
            }
    }
    
    var snappy: Animation {
        .snappy(duration: 0.25, extraBounce: 0)
    }
}

/// TipKit Views
struct Welcome: Tip {
    var title: Text {
        Text("can Your First Document")
    }
    
    var message: Text? {
        Text("Use the camera to scan and save documents securely with DocMatic.")
    }
    
    var image: Image? {
        Image(systemName: "doc.text.viewfinder")
    }
}

struct AllinOne: Tip {
    var title: Text {
        Text("What’s Next?")
    }
    var message: Text? {
        Text("Select from options like editing, sharing, locking, or deleting your document.")
    }
    var image: Image? {
        Image(systemName: "document.badge.ellipsis")
    }
}

struct ClosingTheView: Tip {
    static let setClosingEvent = Event(id: "setClosing")
    
    var title: Text {
        Text("Ready to Leave?")
    }
    var message: Text? {
        Text("Just swipe down to close this screen and get back to work!")
    }
    var image: Image? {
        Image(systemName: "hand.draw")
    }
    
    var rules: [Rule] {
        #Rule(Self.setClosingEvent) { event in
            event.donations.count == 1
        }
    }
}

struct searchingDocuments: Tip {
    static let setSearchEvent = Event(id: "searchEvent")
    
    var title: Text {
        Text("Search Your Documents")
    }
    var message: Text? {
        Text("Type a document name to search for your document you are looking for.")
    }
    
    var rules: [Rule] {
        #Rule(Self.setSearchEvent) { event in
            event.donations.count == 6
        }
    }
}
