//
//  SKWordWidgetEntry.swift
//  WordWidget
//
//  Created by Logout on 17.10.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import Foundation
import WidgetKit

struct SKWordWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: SKWordWidgetConfigurationIntent
    
    let word: String
    let wordTranslation: String

}
