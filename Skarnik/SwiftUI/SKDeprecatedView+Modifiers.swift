//
//  SKDeprecatedView+Modifiers.swift
//  Skarnik
//
//  Created by Logout on 10.11.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import SwiftUI

struct OpaqueTabBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content.toolbarBackground(.visible, for: .tabBar)
        } else {
            content
        }
    }
}

struct ListBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content.scrollContentBackground(.hidden).background(Color.appBackground)
        } else {
            content.background(Color.appBackground)
        }
    }
}

extension Color {
    static let appBackground = Color("BackgroundColor")
}

extension View {
    @ViewBuilder
    func combinedNavigationTitle(_ title: String) -> some View {
        if #available(iOS 14.0, *) {
            navigationTitle(title)
        } else {
            navigationBarTitle(title)
        }
    }
    
    @ViewBuilder
    func combinedBackground(_ color: Color) -> some View {
        if #available(iOS 14.0, *) {
            background(color)
        } else {
            background(color)
        }
    }

    @ViewBuilder
    func combinedVerticalPadding() -> some View {
#if targetEnvironment(macCatalyst)
        padding(.vertical)
#elseif os(iOS)
        self
#endif
    }
}

