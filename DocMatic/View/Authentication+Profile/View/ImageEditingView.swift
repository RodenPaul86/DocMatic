//
//  ImageEditingView.swift
//  DocMatic
//
//  Created by Paul  on 7/6/25.
//

import SwiftUI

struct ImageEditingView: View {
    var image: UIImage
    var onSave: (UIImage) -> Void

    @State private var zoomScale: CGFloat = 1.0
    @GestureState private var gestureZoom: CGFloat = 1.0

    var body: some View {
        VStack {
            Spacer()

            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(zoomScale * gestureZoom)
                    .gesture(
                        MagnificationGesture()
                            .updating($gestureZoom) { value, state, _ in
                                state = value
                            }
                            .onEnded { value in
                                zoomScale *= value
                            }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }

            Spacer()

            Button("Save Image") {
                onSave(image) /// <-- You could apply cropping or filters here before saving
            }
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
    }
}
