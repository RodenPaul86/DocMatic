//
//  aboutView.swift
//  DocMatic
//
//  Created by Paul  on 4/24/25.
//

import SwiftUI

struct aboutView: View {
    
    var body: some View {
        NavigationStack {
            List {
                Section("") {
                    customRow(icon: "app", firstLabel: "Application", secondLabel: Bundle.main.appName)
                    customRow(icon: "curlybraces", firstLabel: "Language", secondLabel: "Swift / SwiftUI")
                    customRow(icon: "square.on.square.dashed", firstLabel: "Version", secondLabel: Bundle.main.appVersion)
                    customRow(icon: "hammer", firstLabel: "Build", secondLabel: Bundle.main.appBuild)
                }
                
                Section(footer: Text("© 2025 Paul Roden II. All Rights Reserved.")) {
                    customRow(icon: "laptopcomputer", firstLabel: "Developer", secondLabel: "Paul Roden Jr.")
                    
                    Text("DocMatic was crafted by a single dedicated indie developer, who relies on your support to grow. \n\nTogether, we'll continuously expand and enrich the experience, ensuring you always get the most out of your subscription. \n\nThank you for being a part of this journey!")
                        .font(.subheadline)
                    
                    customRow(icon: "link", firstLabel: "My Website", secondLabel: "", url: "https://paulrodenjr.org")
                    customRow(icon: "link", firstLabel: "GitHub", secondLabel: "", url: "https://github.com/RodenPaul86")
                    customRow(icon: "link", firstLabel: "DocMatic Website", secondLabel: "", url: "https://docmatic.app")
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    aboutView()
}
