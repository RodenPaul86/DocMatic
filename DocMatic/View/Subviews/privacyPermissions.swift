//
//  privacyPermissions.swift
//  DocMatic
//
//  Created by Paul  on 2/17/25.
//

import SwiftUI

struct privacyPermissions: View {
    @State private var isOn = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Device Permissions")) {
                    HStack {
                        Image(systemName: "camera")
                            .font(.title.bold())
                            .foregroundColor(.purple)
                            .frame(width: 30, height: 30)
                            .padding(.trailing)
                        
                        VStack(alignment: .leading) {
                            Text("Privacy Permissions")
                                .font(.headline.bold())
                            
                            Text("Used to import your events")
                        }
                        
                        Spacer()
                        
                        Toggle("Enable Feature", isOn: $isOn)
                            .labelsHidden()
                            .foregroundStyle(.purple)
                        
                        
                    }
                }
                
            }
            .navigationTitle("Privacy & Permissions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    privacyPermissions()
}
