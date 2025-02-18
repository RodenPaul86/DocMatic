//
//  CGSize+Extensions.swift
//  DocMatic
//
//  Created by Paul  on 1/18/25.
//

import SwiftUI

extension CGSize {
    /// This function will return a new size that fits the given size in an aspect ratio
    func aspectFit(_ to: CGSize) -> CGSize {
        let scaleX = to.width / self.width
        let scaleY = to.height / self.height
        
        let aspectRatio = min(scaleX, scaleY)
        return .init(width: aspectRatio * width, height: aspectRatio * height)
    }
}

extension Bundle {
    var appVersion: String {
        self.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown Version"
    }
    
    var appBuild: String {
        self.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown Build"
    }
    
    var appName: String {
        self.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Unknown App"
    }
}

extension UIDevice {
    var deviceOS: String {
        self.systemName
    }
    
    var OSVersion: String {
        self.systemVersion
    }
}
