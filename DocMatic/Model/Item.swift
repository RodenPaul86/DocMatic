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
        image: "figure.walk.circle.fill",
        title: "Keep an eye on your workout.", scale: 1
    ),
    
    .init(
        image: "figure.run.circle.fill",
        title: "Maintain your cardio fitness.",
        scale: 0.6,
        anchor: .topLeading,
        offset: -70,
        rotation: 30
    ),
    
    .init(
        image: "figure.badminton.circle.fill",
        title: "Take a break from work and relax.",
        scale: 0.5,
        anchor: .bottomLeading,
        offset: -60,
        rotation: -35
    ),
    
    .init(
        image: "figure.climbing.circle.fill",
        title: "Turn climbing into a hobby.",
        scale: 0.4,
        anchor: .bottomLeading,
        offset: -50,
        rotation: 160,
        extraOffset: -120
    ),
    
    .init(
        image: "figure.cooldown.circle.fill",
        title: "Cool down after a workout.",
        scale: 0.35,
        anchor: .bottomLeading,
        offset: -50,
        rotation: 250,
        extraOffset: -100
    )
]
