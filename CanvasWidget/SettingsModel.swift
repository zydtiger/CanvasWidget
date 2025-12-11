//
//  SettingsModel.swift
//  CanvasWidget
//
//  Created by Claude on 12/3/25.
//

import Foundation
import Combine

class SettingsModel: ObservableObject {
    @Published var scraperAPIUrl: String
    @Published var sessionId: String
    @Published var hasChanges: Bool = false

    // Use a shared App Group container
    private let defaults = UserDefaults(suiteName: "group.com.custom.CanvasWidget") ?? .standard
    private let apiUrlKey = "ScraperAPIUrl"
    private let sessionIdKey = "SessionID"
    private let defaultApiUrl = ""
    private let defaultSessionId = ""
    
    init() {
        self.scraperAPIUrl = defaults.string(forKey: apiUrlKey) ?? defaultApiUrl
        self.sessionId = defaults.string(forKey: sessionIdKey) ?? defaultSessionId
    }

    func updateApiUrl(_ newUrl: String) {
        scraperAPIUrl = newUrl
        checkForChanges()
    }

    func updateSessionId(_ newId: String) {
        sessionId = newId
        checkForChanges()
    }

    func saveSettings() {
        defaults.set(scraperAPIUrl, forKey: apiUrlKey)
        defaults.set(sessionId, forKey: sessionIdKey)
        hasChanges = false
    }

    func resetToDefaults() {
        scraperAPIUrl = defaultApiUrl
        sessionId = defaultSessionId
        checkForChanges()
    }

    func discardChanges() {
        scraperAPIUrl = defaults.string(forKey: apiUrlKey) ?? defaultApiUrl
        sessionId = defaults.string(forKey: sessionIdKey) ?? defaultSessionId
        hasChanges = false
    }

    private func checkForChanges() {
        let savedUrl = defaults.string(forKey: apiUrlKey) ?? defaultApiUrl
        let savedSessionId = defaults.string(forKey: sessionIdKey) ?? defaultSessionId
        hasChanges = scraperAPIUrl != savedUrl || sessionId != savedSessionId
    }
}
