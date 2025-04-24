//
//  WhatsNewView.swift
//  TaskSync
//
//  Created by Paul  on 12/31/24.
//

import SwiftUI

struct whatsNewView: View {
    let updates: [Update] = [
        Update(
            title: "DocMatic is Here!",
            version: "v1.0.0",
            date: "February 2025",
            description: """
            We're thrilled to introduce DocMatic, your all-in-one document scanning solution! With this first release, you can scan, organize, and securely store your documents effortlessly. DocMatic is designed to streamline your workflow and simplify document management, wherever you are.
            """,
            imageName: "exampleImage" /// <-  Replace with actual image name
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(updates, id: \.id) { update in
                    UpdateCard(update: update)
                }
            }
            .padding()
            .safeAreaPadding(.bottom, 60)
            .navigationTitle("What's New")
        }
    }
}

struct UpdateCard: View {
    let update: Update

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            // Title and version info
            Text(update.title)
                .font(.title2)
                .fontWeight(.bold)
            Text("\(update.version)  •  \(update.date)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                // Description
                Text(update.description)
                    .font(.body)
                    .foregroundColor(.primary)
                
                /*
                // Optional image
                if let imageName = update.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(10)
                }
                 */
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// Data Model
struct Update: Identifiable {
    let id = UUID()
    let title: String
    let version: String
    let date: String
    let description: String
    let imageName: String? // Optional for updates without images
}

// Preview
#Preview {
    whatsNewView()
}
