//
//  User.swift
//  DocMatic
//
//  Created by Paul  on 6/29/25.
//

import Foundation
import SwiftUI

struct User: Identifiable, Codable {
    let id: String
    let fullname: String
    let email: String
    var profileImageUrl: String?
    
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: fullname) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return ""
    }
}

extension User {
    static var MOCK_USER = User(id: NSUUID().uuidString, fullname: "Steve Jobs", email: "test@example.com")
}
