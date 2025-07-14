//
//  Document.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI
import SwiftData

@Model
class Document {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \DocumentPage.document)
    var pages: [DocumentPage]?
    var isLocked: Bool = false
    /// For Zoom Transitioning
    var uniqueViewID: String = UUID().uuidString
    
    init(name: String, createdAt: Date = Date(), pages: [DocumentPage]? = nil) {
        self.name = name
        self.createdAt = createdAt
        self.pages = pages
    }
}
