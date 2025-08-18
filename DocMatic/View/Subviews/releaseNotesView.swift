//
//  WhatsNewView.swift
//  TaskSync
//
//  Created by Paul  on 12/31/24.
//

import SwiftUI

struct releaseNotesView: View {
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility
    
    let updates: [appUpdate] = [
        appUpdate(
            title: "Foundation for the Future",
            version: "2.0.0",
            date: "July 2025",
            description: "DocMatic 2.0 lays the groundwork for what's next with a complete redesign, better performance, and powerful new features.",
            imageName: "update_2.0",
            features: [
                "Completely redesigned UI for a cleaner, smoother experience.",
                "Optional profile login to personalize your setup.",
                "New Lock & Home Screen widgets for quick access.",
                "Automatic PDF backup to the Files app.",
                "Drag & Drop support for even easier document handling.",
                "Direct file imports into DocMatic from anywhere."
            ],
            bugFixes: [
                "Improved performance and overall stability.",
                "Various under-the-hood fixes for a smoother experience."
            ]
        ),
        
        appUpdate(
            title: "The Polishing Update",
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
            ]
        ),
        
        appUpdate(
            title: "DocMatic is Here!",
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
            .navigationTitle("Release Notes")
            .onAppear {
                withAnimation {
                    tabBarVisibility.isVisible = false
                }
            }
            .onDisappear {
                withAnimation {
                    tabBarVisibility.isVisible = true
                }
            }
            .padding()
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
                        .font(.title2.bold())
                }
                
                Text("v\(update.version) • \(update.date)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Description
                if !update.description.isEmpty {
                    Text(update.description)
                        .font(.body)
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            
            // Centered Optional image
            VStack(spacing: 6) {
                if !update.imageName.isEmpty {
                    Image(update.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .cornerRadius(12)
                        .padding(.bottom, 6)
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
