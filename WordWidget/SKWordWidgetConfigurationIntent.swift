//
//  AppIntent.swift
//  WordWidget
//
//  Created by Logout on 16.10.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import WidgetKit
import AppIntents

struct SKWordWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title = LocalizedStringResource(stringLiteral: "Слова дня")
    static var description = IntentDescription(stringLiteral: "Выпадковае слова і яго пераклад.")
}
