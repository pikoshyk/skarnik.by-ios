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
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.word)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            Spacer(minLength: 4)
            Text(entry.wordTranslation)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
    }
}
