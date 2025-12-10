//
//  AppIntent.swift
//  WidgetExtension
//
//  Created by Zhiyuan Ding on 11/30/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Widget configuration." }
}
