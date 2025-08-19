//
//  widgetHowToo.swift
//  DocMatic
//
//  Created by Paul  on 6/24/25.
//

import SwiftUI

struct WidgetSetupView: View {
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // MARK: Icon
                Image(systemName: "widget.small")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.theme.accent)
                    .padding(.bottom, 4)
                
                // MARK: Title and Description
                Text("Add Widget to Home Screen")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Follow these simple steps to add \(Bundle.main.appName) widgets to your home screen")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // MARK: Steps
                VStack(alignment: .leading, spacing: 20) {
                    StepView(number: 1,
                             icon: "hand.tap",
                             title: "Long Press Home Screen",
                             description: "Long press on any empty space on your home screen until you enter \"jiggle mode\".")
                    
                    StepView(number: 2,
                             icon: "plus",
                             title: "Tap the Plus Button",
                             description: "Look for the \"+\" button in the top-left corner and tap it")
                    
                    StepView(number: 3,
                             icon: "magnifyingglass",
                             title: "Find \(Bundle.main.appName)",
                             description: "Search for \"\(Bundle.main.appName)\" or scroll down to find our app")
                    
                    StepView(number: 4,
                             icon: "checkmark",
                             title: "Add Widget",
                             description: "Tap \"Add Widget\" to place it on your home screen. You can move it anywhere you like!")
                }
                .padding()
                
                Spacer()
                
                // MARK: Comfermation Button
                /*
                Button(action: {
                    dismiss()
                }) {
                    Text("Got It!")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                 */
            }
            .padding()
            .onAppear {
                withAnimation {
                    tabBarVisibility.isVisible = false
                }
            }
            .onDisappear {
                withAnimation {
                    tabBarVisibility.isVisible = true
                }
            }
        }
    }
}

struct StepView: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.theme.accent))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(Color("Default"))
                    Text(title)
                        .font(.headline)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    WidgetSetupView()
}
