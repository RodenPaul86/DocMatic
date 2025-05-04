//
//  DocumentViewModel.swift
//  DocMatic
//
//  Created by Paul  on 5/4/25.
//

import SwiftUI

enum SortOrder: String {
    case newestFirst
    case oldestFirst
}

class DocumentViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var sortOrder: SortOrder {
        didSet {
            UserDefaults.standard.set(sortOrder.rawValue, forKey: "sortOrder")
        }
    }
    
    @Published var documents: [Document] = []
    
    init() {
        let savedValue = UserDefaults.standard.string(forKey: "sortOrder")
        self.sortOrder = SortOrder(rawValue: savedValue ?? "") ?? .newestFirst
    }
    
    // MARK: Filtered documents based on search text
    var filteredDocuments: [Document] {
        let base = searchText.isEmpty ? documents : documents.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        return switch sortOrder {
        case .newestFirst:
            base.sorted { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            base.sorted { $0.createdAt < $1.createdAt }
        }
    }
}
