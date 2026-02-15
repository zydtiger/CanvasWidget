//
//  CanvasWidgetApp.swift
//  CanvasWidget
//
//  Created by Zhiyuan Ding on 11/27/25.
//

import AppKit
import SwiftUI
import UserNotifications
import WidgetKit

@main
struct CanvasWidgetApp: App {
    init() {
        requestNotificationAuthorization()
        refreshAllWidgets()
    }

    var body: some Scene {
        WindowGroup {
            EntryView()
                .onOpenURL { url in
                    // Handle URL from widget clicks - open in default browser
                    NSWorkspace.shared.open(url)
                }
        }
        .defaultSize(width: 800, height: 600)
    }

    /// Request notification authorization on app launch
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification authorization granted")
            } else if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    /// Refresh all widgets on app launch
    private func refreshAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        print("Refreshed all widget timelines")
    }
}
