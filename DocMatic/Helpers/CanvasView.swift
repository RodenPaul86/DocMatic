//
//  CanvasView.swift
//  DocMatic
//
//  Created by Paul  on 8/18/25.
//

import SwiftUI
import PencilKit

struct CanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var showTools: Bool
    let canvas = PKCanvasView()
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.delegate = context.coordinator
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
        
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first,
           let toolPicker = PKToolPicker.shared(for: window) {
            
            if showTools {
                toolPicker.setVisible(true, forFirstResponder: uiView)
                toolPicker.addObserver(uiView)
                uiView.becomeFirstResponder()
            } else {
                toolPicker.setVisible(false, forFirstResponder: uiView)
                uiView.resignFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasRepresentable
        init(_ parent: CanvasRepresentable) { self.parent = parent }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}
