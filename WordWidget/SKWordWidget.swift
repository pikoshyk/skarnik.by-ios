//
//  SKWordWidget.swift
//  WordWidget
//
//  Created by Logout on 16.10.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import WidgetKit
import SwiftUI


struct SKWordWidget: Widget {
    let kind: String = "SKWordOfTheDay"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SKWordWidgetConfigurationIntent.self, provider: SKWordTimelineProvider()) { entry in
            SKWordWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
