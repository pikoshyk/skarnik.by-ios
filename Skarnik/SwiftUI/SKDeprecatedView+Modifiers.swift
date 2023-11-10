//
//  SKDeprecatedView+Modifiers.swift
//  Skarnik
//
//  Created by Logout on 10.11.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import SwiftUI

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

