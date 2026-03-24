//
//  SKWordWidgetView.swift
//  WordWidget
//
//  Created by Logout on 17.10.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import SwiftUI
import WidgetKit
import Foundation

extension View {
    func universalForeground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 15.0, iOS 15.0, *) {
            return self.foregroundStyle(color)
        } else {
            return self.foregroundColor(color)
        }
    }
}

struct SKWordWidgetView : View {
    var entry: SKWordTimelineProvider.Entry

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    self.textWord
                        .universalForeground(Color.accent)
                    self.textTranslation
                        .universalForeground(.secondary)
                }
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
        }
        .widgetURL(entry.deepLinkURL)
    }
    
    var textWord: some View {
        Text(entry.word.uppercased())
            .lineLimit(2)
            .font(.system(size: 12, weight: .bold))
    }
    
    var textTranslation: some View {
        Text(entry.wordTranslation)
            .font(.system(size: 14))
            .fontWeight(.regular)
    }
}
