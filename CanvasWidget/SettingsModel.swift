//
//  SettingsModel.swift
//  CanvasWidget
//
//  Created by Claude on 12/3/25.
//

import Foundation
import Combine

class SettingsModel: ObservableObject {
    @Published var pythonInterpreterPath: String
    @Published var sessionId: String
    @Published var hasChanges: Bool = false
    
    // Use a shared App Group container
    private let defaults = UserDefaults(suiteName: "group.com.custom.CanvasWidget") ?? .standard
    private let pythonPathKey = "PythonInterpreterPath"
    private let sessionIdKey = "SessionID"
    private let defaultPythonPath = "/usr/bin/python3"
    private let defaultSessionId = ""
    
    init() {
        self.pythonInterpreterPath = defaults.string(forKey: pythonPathKey) ?? defaultPythonPath
        self.sessionId = defaults.string(forKey: sessionIdKey) ?? defaultSessionId
    }
    
    func updatePythonPath(_ newPath: String) {
        pythonInterpreterPath = newPath
        checkForChanges()
    }
    
    func updateSessionId(_ newId: String) {
        sessionId = newId
        checkForChanges()
    }
    
    func saveSettings() {
        defaults.set(pythonInterpreterPath, forKey: pythonPathKey)
        defaults.set(sessionId, forKey: sessionIdKey)
        hasChanges = false
    }
    
    func resetToDefaults() {
        pythonInterpreterPath = defaultPythonPath
        sessionId = defaultSessionId
        checkForChanges()
    }
    
    func discardChanges() {
        pythonInterpreterPath = defaults.string(forKey: pythonPathKey) ?? defaultPythonPath
        sessionId = defaults.string(forKey: sessionIdKey) ?? defaultSessionId
        hasChanges = false
    }
    
    private func checkForChanges() {
        let savedPath = defaults.string(forKey: pythonPathKey) ?? defaultPythonPath
        let savedSessionId = defaults.string(forKey: sessionIdKey) ?? defaultSessionId
        hasChanges = pythonInterpreterPath != savedPath || sessionId != savedSessionId
    }
}
