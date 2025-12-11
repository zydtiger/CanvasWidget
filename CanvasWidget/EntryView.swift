//
//  EntryView.swift
//  CanvasWidget
//
//  Created by Zhiyuan Ding on 11/27/25.
//

import SwiftUI

struct EntryView: View {
    @StateObject private var settings = SettingsModel()
    @State private var showingInvalidURLAlert = false
    @State private var manualURLInput = ""
    @State private var selectedSidebarItem: SidebarItem = .settings

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SidebarItem.allCases, id: \.self, selection: $selectedSidebarItem) { item in
                Label(item.rawValue, systemImage: item.systemImage)
                    .tag(item)
            }
            .navigationTitle("CanvasWidget")
        } detail: {
            // Detail view based on selection
            Group {
                switch selectedSidebarItem {
                case .settings:
                    settingsView
                case .announcements:
                    AnnouncementsView()
                case .assignments:
                    AssignmentsView()
                }
            }
            .navigationTitle(selectedSidebarItem.rawValue)
        }
        .alert("Invalid API URL", isPresented: $showingInvalidURLAlert) {
            Button("OK") { }
        } message: {
            Text("The API URL is invalid. Please ensure the server is running and returns {\"running\": true}.")
        }
        .onAppear {
            manualURLInput = settings.scraperAPIUrl
        }
    }

    private var settingsView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "gear")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                
                Text("CanvasWidget Settings")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Change connection settings here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            // Settings content
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scraper API URL")
                        .font(.headline)

                    HStack {
                        TextField("Enter Scraper API URL", text: $manualURLInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))

                        Button("Validate") {
                            validateAPIURL(manualURLInput)
                        }
                        .disabled(manualURLInput.isEmpty)
                        .controlSize(.regular)
                    }
                }
                
                // Session ID section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session ID")
                        .font(.headline)
                    
                    TextField("Enter Session ID", text: Binding(
                        get: { settings.sessionId },
                        set: { settings.updateSessionId($0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                }
                
                if settings.hasChanges {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                        Text("Unsaved changes")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Spacer()
                    }
                }
            }
            
            Spacer()
            
            // Buttons
            HStack {
                Button("Cancel") {
                    settings.discardChanges()
                    manualURLInput = settings.scraperAPIUrl
                }
                .disabled(!settings.hasChanges)
                .controlSize(.large)
                
                Spacer()
                
                Button("Save") {
                    settings.saveSettings()
                }
                .disabled(!settings.hasChanges)
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom)
        }
        .padding(.horizontal, 32)
        .frame(minWidth: 480, minHeight: 360)
    }
    
    private func validateAPIURL(_ urlString: String) {
        guard !urlString.isEmpty else { return }

        // Validate URL format
        guard let url = URL(string: urlString) else {
            showingInvalidURLAlert = true
            return
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Make the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("API validation failed: \(error)")
                    showingInvalidURLAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    print("Invalid response status code")
                    showingInvalidURLAlert = true
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      json["running"] as? Bool == true else {
                    print("Invalid JSON response or running flag not set to true")
                    showingInvalidURLAlert = true
                    return
                }

                // Success - update the settings
                settings.updateApiUrl(urlString)
                print("Successfully validated API URL: \(urlString)")
            }
        }.resume()
    }
}

#Preview {
    EntryView()
}
