//
//  StoreProductView.swift
//  DocMatic
//
//  Created by Paul  on 5/25/25.
//

import SwiftUI
import StoreKit

struct StoreProductPresenter: UIViewControllerRepresentable {
    let appStoreID: Int
    @Binding var isPresented: Bool
    
    class Coordinator: NSObject, SKStoreProductViewControllerDelegate {
        var parent: StoreProductPresenter
        var hasPresented = false
        
        init(_ parent: StoreProductPresenter) {
            self.parent = parent
        }
        
        func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            viewController.dismiss(animated: true) {
                self.parent.isPresented = false
                self.hasPresented = false /// <-- Reset the flag
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard context.coordinator.hasPresented == false, isPresented else { return }
        context.coordinator.hasPresented = true
        
        let storeVC = SKStoreProductViewController()
        storeVC.delegate = context.coordinator
        
        let parameters = [SKStoreProductParameterITunesItemIdentifier: NSNumber(value: appStoreID)]
        
        storeVC.loadProduct(withParameters: parameters) { loaded, error in
            if loaded {
                uiViewController.present(storeVC, animated: true)
            } else {
                print("Error loading product: \(error?.localizedDescription ?? "Unknown error")")
                isPresented = false
                context.coordinator.hasPresented = false // reset on error too
            }
        }
    }
}
