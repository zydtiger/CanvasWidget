//
//  ContentView.swift
//  CanvasWidget
//
//  Created by Zhiyuan Ding on 11/27/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settings = SettingsModel()
    @State private var showingInvalidPathAlert = false
    @State private var manualPathInput = ""

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("CanvasWidget Settings")
                    .font(.title)
                    .fontWeight(.semibold)
            }
            .padding(.top)

            // Settings content
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Python Interpreter Path")
                        .font(.headline)

                    HStack {
                        TextField("Enter Python interpreter path", text: $manualPathInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))

                        Button("Validate") {
                            validateManualPath()
                        }
                        .disabled(manualPathInput.isEmpty)
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
                    manualPathInput = settings.pythonInterpreterPath
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
        .alert("Invalid Path", isPresented: $showingInvalidPathAlert) {
            Button("OK") { }
        } message: {
            Text("The selected path is invalid. Please select a valid Python 3 interpreter.")
        }
        .onAppear {
            manualPathInput = settings.pythonInterpreterPath
        }
    }

    private func validatePythonPath(_ url: URL) {
        let path = url.path

        // Check if the file is executable
        guard FileManager.default.isExecutableFile(atPath: path) else {
            print("Selected file is not executable")
            showingInvalidPathAlert = true
            DispatchQueue.main.async {
                self.settings.discardChanges()
            }
            return
        }

        // Run the executable with --version flag to validate it's Python 3
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["--version"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                if output.lowercased().contains("python 3") {
                    settings.updatePythonPath(path)
                    print("Successfully set Python path: \(path)")
                    print("Version output: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
                } else {
                    print("Selected executable is not Python 3: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
                    showingInvalidPathAlert = true
                    DispatchQueue.main.async {
                        self.settings.discardChanges()
                    }
                }
            } else {
                print("Failed to execute Python interpreter. Exit code: \(process.terminationStatus)")
                if !output.isEmpty {
                    print("Error output: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
                showingInvalidPathAlert = true
                DispatchQueue.main.async {
                    self.settings.discardChanges()
                }
            }
        } catch {
            print("Failed to run Python interpreter: \(error)")
            showingInvalidPathAlert = true
            DispatchQueue.main.async {
                self.settings.discardChanges()
            }
        }
    }

    private func validateManualPath() {
        guard !manualPathInput.isEmpty else { return }

        let url = URL(fileURLWithPath: manualPathInput)
        validatePythonPath(url)
    }
}

#Preview {
    ContentView()
}
