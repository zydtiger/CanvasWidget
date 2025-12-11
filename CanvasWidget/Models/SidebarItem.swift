//
//  SidebarItem.swift
//  CanvasWidget
//
//  Created by Claude on 12/10/25.
//

import Foundation

enum SidebarItem: String, CaseIterable {
    case settings = "Settings"
    case announcements = "Announcements"
    case assignments = "Assignments"

    var systemImage: String {
        switch self {
        case .settings: return "gear"
        case .announcements: return "speaker.wave.2"
        case .assignments: return "checkmark.rectangle"
        }
    }
}