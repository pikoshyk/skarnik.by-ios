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

struct SKWordWidgetView : View {
    var entry: SKWordTimelineProvider.Entry

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.word.uppercased())
                    .lineLimit(2)
                    .font(.system(size: 12))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accent)
                Text(entry.wordTranslation)
                    .font(.system(size: 14))
                    .fontWeight(.regular)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        Spacer(minLength: 0)
    }
}
