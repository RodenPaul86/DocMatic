//
//  Color.swift
//  DocMatic
//
//  Created by Paul  on 7/7/25.
//

import Foundation
import SwiftUI

extension Color {
    static let theme = ColorTheme()
    static let launch = LaunchTheme()
}

struct ColorTheme {
    let accent = Color("Default")
}

struct LaunchTheme {
    let accent = Color("LaunchAccentColor").gradient
    let background = Color("LaunchBackgroundColor")
}
