//
//  DocMatic_widgetBundle.swift
//  DocMatic.widget
//
//  Created by Paul  on 6/15/25.
//

import WidgetKit
import SwiftUI

@main
struct DocMatic_widgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        ScanDocWidget()
        //DocCountWidget()
        //DocViewerWidget()
    }
}
