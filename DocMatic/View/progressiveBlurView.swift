//
//  ProgressiveBlurView.swift
//  DocMatic
//
//  Created by Paul  on 6/11/25.
//

import SwiftUI

struct progressiveBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> customBlurView {
        let view = customBlurView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: customBlurView, context: Context) {
        
    }
}

class customBlurView: UIVisualEffectView {
    init() {
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        
        removeFilters()
        
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            DispatchQueue.main.async {
                self.removeFilters()
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Removing All Filters
    private func removeFilters() {
        if let filterLayer = layer.sublayers?.first {
            filterLayer.filters = []
        }
    }
}
