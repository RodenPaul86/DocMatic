//
//  Items.swift
//  DocMatic
//
//  Created by Paul  on 6/21/25.
//

import SwiftUI

struct Item: Identifiable {
    var id: String = UUID().uuidString
    var image: String
    var title: String
    var description: String
    
    // MARK: Locations of each icons
    var scale: CGFloat = 1
    var anchor: UnitPoint = .center
    var offset: CGFloat = 0
    var rotation: CGFloat = 0
    var zindex: CGFloat = 0
    var extraOffset: CGFloat = -350
}

// MARK: Sample Intro Page Items
let items: [Item] = [
    .init(
        image: "doc.viewfinder",
        title: "Scan & Digitize Smarter.",
        description: "Capture clear, high-quality scans in seconds with your iPhone or iPad. Auto-edge detection, color correction, and multi-page support make scanning effortless.",
        scale: 1
    ),
    
    .init(
        image: "lock.shield",
        title: "Secure Your Docs.",
        description: "Protect sensitive documents with Face ID or Touch ID. Keep your private information locked behind biometric security.",
        scale: 0.6,
        anchor: .topLeading,
        offset: -70,
        rotation: 30
    ),
    
    .init(
        image: "tray.full",
        title: "Storing Scanned Files",
        description: "Securely store your scanned documents in one place—no more worrying about misplacing important files.",
        scale: 0.5,
        anchor: .bottomLeading,
        offset: -60,
        rotation: -35
    ),
    
    .init(
        image: "square.and.arrow.up",
        title: "Export & Share Anywhere",
        description: "Save to Files, print, or share via AirDrop, email, and more. DocMatic keeps your documents moving smoothly.",
        scale: 0.4,
        anchor: .bottomLeading,
        offset: -50,
        rotation: 160,
        extraOffset: -120
    ),
    
    .init(
        image: "party.popper",
        title: "Welcome to DocMatic!",
        description: "Thanks so much for giving my app a try. I made it with users like you in mind!",
        scale: 0.35,
        anchor: .bottomLeading,
        offset: -50,
        rotation: 250,
        extraOffset: -100
    )
]
