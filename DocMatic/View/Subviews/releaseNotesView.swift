//
//  WhatsNewView.swift
//  TaskSync
//
//  Created by Paul  on 12/31/24.
//

import SwiftUI

struct releaseNotesView: View {
    let updates: [appUpdate] = [
        appUpdate(title: "Foundation for the Future",
                  version: "2.0.0",
                  date: "July 2025",
                  description: "",
                  imageName: "",
                  features: [
                    "UI/UX Redesign and Improvements.",
                    "Optional profile login.",
                    "Lock & Home screen widgets",
                    "Drag and Drop PDF's"],
                  bugFixes: [
                    "General proformance upgrades and bug fixes."
                  ]),
        
        appUpdate(title: "The Polishing Update",
                  version: "1.1.0",
                  date: "May 2025",
                  description: "",
                  imageName: "",
                  features: [
                    "12 new app icons.",
                    "DocMatic now has a full-screen, otimized iPad app.",
                    "Redesigned settings UI.",
                    "Long press gestures for quick access to frequently used features."
                  ],
                  bugFixes: [
                    "Adjusted the color of the default app icon.",
                    "Addressed a bug related to document thumbnails.",
                    "Squashed other bugs."
                  ]),
        
        appUpdate(title: "DocMatic is Here!",
                  version: "1.0.0",
                  date: "February 2025",
                  description: """
We're thrilled to introduce DocMatic, your all-in-one document scanning solution! With this first release, you can scan, organize, and securely store your documents effortlessly. 

DocMatic is designed to streamline your workflow and simplify document management, wherever you are.
""",
                  imageName: "",
                  features: nil,
                  bugFixes: nil)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(updates, id: \.id) { update in
                    UpdateCard(update: update)
                }
            }
            .padding()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 80) /// <-- Reserve space for the tab bar
            }
            .navigationTitle("Release Notes")
        }
    }
}

struct UpdateCard: View {
    let update: appUpdate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Centered Title and Version/Date
            VStack(spacing: 4) {
                if !update.title.isEmpty {
                    Text(update.title)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("v\(update.version) • \(update.date)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            
            // Description
            if !update.description.isEmpty {
                Text(update.description)
                    .font(.body)
            }
            
            // Centered Optional image
            VStack(spacing: 4) {
                if !update.imageName.isEmpty {
                    Image(update.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .cornerRadius(12)
                        .padding(.bottom, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            
            // Features
            if let features = update.features, !features.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What's New")
                        .font(.headline)
                    ForEach(features, id: \.self) { feature in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(feature)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            
            // Bug Fixes
            if let bugFixes = update.bugFixes, !bugFixes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bug Fixes")
                        .font(.headline)
                    ForEach(bugFixes, id: \.self) { fix in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(fix)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color("BGTile"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: Data Model
struct appUpdate: Identifiable {
    let id = UUID()
    let title: String
    let version: String
    let date: String
    let description: String
    let imageName: String
    let features: [String]?
    let bugFixes: [String]?
}

// MARK: Preview
#Preview {
    releaseNotesView()
}
