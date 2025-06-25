//
//  CustomizationView.swift
//  DocMatic
//
//  Created by Paul  on 6/24/25.
//

import SwiftUI

struct CustomizationView: View {
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                
            }
            .navigationTitle("Customizations")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CustomizationView()
}
