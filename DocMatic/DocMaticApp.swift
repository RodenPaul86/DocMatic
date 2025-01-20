//
//  DocMaticApp.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI
import SwiftData
import TipKit

@main
struct DocMaticApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Document.self)
                .task {
                    //try? Tips.resetDatastore()
                    try? Tips.configure([
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
    }
}
