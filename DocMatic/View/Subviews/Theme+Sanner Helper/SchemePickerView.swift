//
//  SchemePickerView.swift
//  DocMatic
//
//  Created by Paul  on 1/20/25.
//

import SwiftUI

enum AppScheme: String {
    case dark = "Dark"
    case light = "Light"
    case device = "Device"
}

fileprivate struct SchemePreview: Identifiable {
    var id: UUID = .init()
    var image: UIImage?
    var text: String
}

struct SchemeHostView<Content: View>: View {
    var content: Content
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        
        if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow {
            window.overrideUserInterfaceStyle = appScheme == .dark ? .dark : appScheme == .light ? .light : .unspecified
        }
    }
    
    // MARK: View Properties
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
    @Environment(\.colorScheme) private var scheme
    @State private var schemePreviews: [SchemePreview] = []
    @State private var showSheet: Bool = false
    @State private var overlayWindow: UIWindow?
    
    var body: some View {
        content
            .sheet(isPresented: $showSheet, onDismiss: {
                schemePreviews = []
                showPickerView = false
            }, content: {
                SchemePickerView(previews: $schemePreviews)
            })
            .onChange(of: showPickerView) { oldValue, newValue in
                if newValue {
                    generateSchemePreviews()
                } else {
                    showSheet = false
                }
            }
            .onAppear {
                if let scene = (UIApplication.shared.connectedScenes.first as? UIWindowScene), overlayWindow == nil {
                    let window = UIWindow(windowScene: scene)
                    window.backgroundColor = .clear
                    window.isHidden = false
                    window.isUserInteractionEnabled = false
                    let emptyController = UIViewController()
                    emptyController.view.backgroundColor = .clear
                    window.rootViewController = emptyController
                    
                    overlayWindow = window
                }
            }
    }
    
    // MARK: Generating Scheme Previews and then pushing the sheet view
    private func generateSchemePreviews() {
        Task {
            if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow, schemePreviews.isEmpty {
                let size = window.screen.bounds.size
                let defaultStyle = window.overrideUserInterfaceStyle
                
                let defaultSchemePreview = window.subviews.first?.image(size)
                schemePreviews.append(
                    .init(image: defaultSchemePreview,
                          text: scheme == .dark ? AppScheme.dark.rawValue : AppScheme.light.rawValue))
                
                showOverlayImageView(defaultSchemePreview!)
                
                window.overrideUserInterfaceStyle = scheme.oppositeInterfaceStyle
                let otherSchemePreviewImage = window.subviews.first?.image(size)
                
                schemePreviews.append(
                    .init(image: otherSchemePreviewImage,
                          text: scheme == .dark ? AppScheme.light.rawValue : AppScheme.dark.rawValue))
                
                if scheme == .dark { schemePreviews = schemePreviews.reversed() }
                
                /// Resetting to it's default Style
                window.overrideUserInterfaceStyle = defaultStyle
                try? await Task.sleep(for: .seconds(0))
                
                removeOverlayImageView()
                
                showSheet = true
            }
        }
    }
    
    private func showOverlayImageView(_ image: UIImage) {
        if overlayWindow?.rootViewController?.view.subviews.isEmpty ?? false {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            
            overlayWindow?.rootViewController?.view.addSubview(imageView)
        }
    }
    
    private func removeOverlayImageView() {
        overlayWindow?.rootViewController?.view.subviews.forEach {
            $0.removeFromSuperview()
        }
    }
}

fileprivate extension ColorScheme {
    var oppositeInterfaceStyle: UIUserInterfaceStyle {
        return self == .dark ? .light : .dark
    }
    
}

// MARK: Appearance View
struct SchemePickerView: View {
    @Binding fileprivate var previews: [SchemePreview]
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @State private var localSchemeState: AppScheme = .device
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Appearance")
                .font(.title3.bold())
            
            Divider()
            
            Spacer(minLength: 0)
            
            GeometryReader { _ in
                HStack(spacing: 10) {
                    ForEach(previews) { preview in
                        SchemeCardView([preview])
                    }
                    SchemeCardView(previews)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            if #available(iOS 26.0, *) {
                ZStack {}
            } else {
                ZStack {
                    Rectangle()
                        .fill(.background)
                    
                    Rectangle()
                        .fill(Color.primary.opacity(0.05))
                }
                .clipShape(.rect(cornerRadius: 20))
            }
        }
        .padding([.horizontal, .bottom], 10)
        .presentationDetents([.height(320)])
        .presentationBackground(.clear)
        .onChange(of: appScheme, initial: true) { oldValue, newValue in
            localSchemeState = newValue
        }
    }
    
    @ViewBuilder
    fileprivate func SchemeCardView(_ preview: [SchemePreview]) -> some View {
        let isSelected = localSchemeState.rawValue == (preview.count == 2 ? "Device" : preview.first?.text ?? "")
        
        VStack(spacing: 6) {
            if let image = preview.first?.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay {
                        if let secondImage = preview.last?.image, preview.count == 2 {
                            GeometryReader {
                                let width = $0.size.width / 2
                                
                                Image(uiImage: secondImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .mask(alignment: .trailing) {
                                        Rectangle()
                                            .frame(width: width)
                                    }
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color.theme.accent : Color.gray.gradient, lineWidth: 1)
                            .animation(.easeInOut, value: isSelected)
                    )
            }
            
            let text = preview.count == 2 ? "Device" : preview.first?.text ?? ""
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.gray)
            
            ZStack {
                Image(systemName: "circle")
                
                if localSchemeState.rawValue == text {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.theme.accent)
                        .transition(.blurReplace)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onTapGesture {
            if preview.count == 2 {
                appScheme = .device
            } else {
                appScheme = preview.first?.text == AppScheme.dark.rawValue ? .dark : .light
            }
            updateScheme()
            if isHapticsEnabled {
                hapticManager.shared.notify(.impact(.light))
            }
        }
    }
    
    private func updateScheme() {
        if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow {
            window.overrideUserInterfaceStyle = appScheme == .dark ? .dark : appScheme == .light ? .light : .unspecified
        }
    }
}

extension UIView {
    func image(_ size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            drawHierarchy(in: .init(origin: .zero, size: size), afterScreenUpdates: true)
        }
    }
}

