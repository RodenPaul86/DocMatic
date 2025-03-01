//
//  DocumentCardView.swift
//  DocMatic
//
//  Created by Paul  on 1/18/25.
//

import SwiftUI

struct DocumentCardView: View {
    var document: Document
    var animationID: Namespace.ID /// <- For zoom transition
    
    /// View Properties
    @State private var downsizedImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            /// Sorting Pages
            if let firstPage = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }).first {
                GeometryReader { geometry in
                    let size = geometry.size
                    
                    if let downsizedImage {
                        Image(uiImage: downsizedImage)
                            .resizable()
                            .aspectRatio(8.5 / 11, contentMode: .fill) /// <- Letter-size aspect ratio
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 15)) /// <- Rounded corners for paper look
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1) /// <- Subtle border to mimic paper edge
                            )
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5) /// <- Enhanced shadow for paper effect
                    } else {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .task(priority: .high) {
                                /// Downsizing Image
                                guard let image = UIImage(data: firstPage.pageData) else { return }
                                let aspectSize = image.size.aspectFit(.init(width: 150, height: 150))
                                let renderer = UIGraphicsImageRenderer(size: aspectSize)
                                let resizedImage = renderer.image { context in
                                    image.draw(in: .init(origin: .zero, size: aspectSize))
                                }
                                
                                await MainActor.run {
                                    downsizedImage = resizedImage
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5) /// <- Enhanced shadow for paper effect
                    }
                    
                    if document.isLocked {
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                            
                            Image(systemName: "lock.fill")
                                .font(.title3)
                        }
                    }
                }
                .aspectRatio(8.5 / 11, contentMode: .fit) /// <- Maintain letter-size aspect ratio
                .clipShape(RoundedRectangle(cornerRadius: 15)) /// <- Rounded corners for paper effect
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5) /// <- Shadow for the entire card
            }
            
            Text(document.name)
                .font(.callout)
                .lineLimit(1)
                .padding(.top, 10)
            
            Text(document.createdAt.formatted(date: .numeric, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .padding(10) /// <- Padding for a cleaner look around the content
        .background(
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ) /// <- Enhanced gradient for depth
                .blur(radius: 1) /// <- Subtle blur for a smoother texture
                
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1) /// <- Subtle border for a "paper edge" effect
            }
                .clipShape(RoundedRectangle(cornerRadius: 15)) /// <- Keep rounded corners for the "paper" effect
        )
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5) /// <- Paper shadow effect
    }
}
