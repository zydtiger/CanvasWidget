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

    @Parameter(title: "Content Type", default: .announcements)
    var contentType: WidgetContentType
}

enum WidgetContentType: String, AppEnum {
    case announcements
    case assignments

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Content Type"

    static var caseDisplayRepresentations: [WidgetContentType: DisplayRepresentation] = [
        .announcements: "Announcements",
        .assignments: "Assignments"
    ]
}
