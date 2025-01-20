//
//  SettingsView.swift
//  DocMatic
//
//  Created by Paul  on 1/20/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Settings")) {
                    Button {
                        showPickerView.toggle()
                    } label: {
                        Text("Theme Settings")
                            .foregroundStyle(.black)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .animation(.easeInOut, value: appScheme)
    }
}

#Preview {
    SettingsView()
}
