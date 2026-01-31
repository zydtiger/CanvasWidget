//
//  Provider.swift
//  CanvasWidget
//
//  Created by Claude on 12/10/25.
//

import Combine
import Foundation

@MainActor
class Provider: ObservableObject {
    static let shared = Provider()

    @Published var announcements: [Announcement] = []
    @Published var assignments: [Assignment] = []
    @Published var isLoadingAnnouncements = false
    @Published var isLoadingAssignments = false
    @Published var errorMessage: String?

    private let defaults = UserDefaults(suiteName: "group.com.custom.CanvasWidget") ?? .standard
    private let announcementsKey = "CachedAnnouncements"
    private let assignmentsKey = "CachedAssignments"

    private init() {
        loadCachedData()
    }

    func fetchAnnouncements() async {
        isLoadingAnnouncements = true
        errorMessage = nil

        // Get settings from UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.custom.CanvasWidget") ?? .standard
        guard let scraperAPIUrl = defaults.string(forKey: "ScraperAPIUrl"),
            let sessionId = defaults.string(forKey: "SessionID"),
            !scraperAPIUrl.isEmpty,
            !sessionId.isEmpty
        else {
            isLoadingAnnouncements = false
            errorMessage = "Missing scraper API URL or session ID in settings"
            return
        }

        // Create URL
        guard let url = URL(string: "\(scraperAPIUrl)/announcements") else {
            isLoadingAnnouncements = false
            errorMessage = "Invalid announcements URL"
            return
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionId)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                isLoadingAnnouncements = false
                handleError(
                    NSError(
                        domain: "ProviderError", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response"]),
                    context: "Failed to fetch announcements")
                return
            }

            guard httpResponse.statusCode == 200 else {
                isLoadingAnnouncements = false
                handleError(
                    NSError(
                        domain: "ProviderError", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "HTTP error"]),
                    context: "Failed to fetch announcements",
                    response: httpResponse,
                    data: data)
                return
            }

            // Parse JSON response
            let decodedAnnouncements = try JSONDecoder().decode([Announcement].self, from: data)
            let uniqueAnnouncements = deduplicateAnnouncements(decodedAnnouncements)
            self.announcements = uniqueAnnouncements
            saveAnnouncementsToCache(uniqueAnnouncements)
            print(
                "Successfully fetched \(decodedAnnouncements.count) announcements (\(uniqueAnnouncements.count) unique)"
            )

        } catch {
            isLoadingAnnouncements = false
            handleError(error, context: "Failed to fetch announcements")
        }

        isLoadingAnnouncements = false
    }

    func fetchAssignments() async {
        isLoadingAssignments = true
        errorMessage = nil

        // Get settings from UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.custom.CanvasWidget") ?? .standard
        guard let scraperAPIUrl = defaults.string(forKey: "ScraperAPIUrl"),
            let sessionId = defaults.string(forKey: "SessionID"),
            !scraperAPIUrl.isEmpty,
            !sessionId.isEmpty
        else {
            isLoadingAssignments = false
            errorMessage = "Missing scraper API URL or session ID in settings"
            return
        }

        // Create URL
        guard let url = URL(string: "\(scraperAPIUrl)/assignments") else {
            isLoadingAssignments = false
            errorMessage = "Invalid assignments URL"
            return
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionId)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                isLoadingAssignments = false
                handleError(
                    NSError(
                        domain: "ProviderError", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response"]),
                    context: "Failed to fetch assignments")
                return
            }

            guard httpResponse.statusCode == 200 else {
                isLoadingAssignments = false
                handleError(
                    NSError(
                        domain: "ProviderError", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "HTTP error"]),
                    context: "Failed to fetch assignments",
                    response: httpResponse,
                    data: data)
                return
            }

            // Parse JSON response
            let decodedAssignments = try JSONDecoder().decode([Assignment].self, from: data)
            let uniqueAssignments = deduplicateAssignments(decodedAssignments)
            self.assignments = uniqueAssignments
            saveAssignmentsToCache(uniqueAssignments)
            print(
                "Successfully fetched \(decodedAssignments.count) assignments (\(uniqueAssignments.count) unique)"
            )

        } catch {
            isLoadingAssignments = false
            handleError(error, context: "Failed to fetch assignments")
        }

        isLoadingAssignments = false
    }

    // MARK: - Caching Methods

    private func loadCachedData() {
        if let cachedAnnouncements = getCachedAnnouncements() {
            self.announcements = cachedAnnouncements
            print("Loaded \(cachedAnnouncements.count) cached announcements")
        }

        if let cachedAssignments = getCachedAssignments() {
            self.assignments = cachedAssignments
            print("Loaded \(cachedAssignments.count) cached assignments")
        }
    }

    private func getCachedAnnouncements() -> [Announcement]? {
        guard let data = defaults.data(forKey: announcementsKey) else { return nil }
        do {
            return try JSONDecoder().decode([Announcement].self, from: data)
        } catch {
            print("Error decoding cached announcements: \(error)")
            return nil
        }
    }

    private func getCachedAssignments() -> [Assignment]? {
        guard let data = defaults.data(forKey: assignmentsKey) else { return nil }
        do {
            return try JSONDecoder().decode([Assignment].self, from: data)
        } catch {
            print("Error decoding cached assignments: \(error)")
            return nil
        }
    }

    private func saveAnnouncementsToCache(_ announcements: [Announcement]) {
        do {
            let data = try JSONEncoder().encode(announcements)
            defaults.set(data, forKey: announcementsKey)
            print("Saved \(announcements.count) announcements to cache")
        } catch {
            print("Error encoding announcements for cache: \(error)")
        }
    }

    private func saveAssignmentsToCache(_ assignments: [Assignment]) {
        do {
            let data = try JSONEncoder().encode(assignments)
            defaults.set(data, forKey: assignmentsKey)
            print("Saved \(assignments.count) assignments to cache")
        } catch {
            print("Error encoding assignments for cache: \(error)")
        }
    }

    // MARK: - Deduplication Methods

    private func deduplicateAnnouncements(_ announcements: [Announcement]) -> [Announcement] {
        var seenIDs = Set<String>()
        var uniqueAnnouncements: [Announcement] = []
        var duplicatesRemoved = 0

        for announcement in announcements {
            if !seenIDs.contains(announcement.id) {
                seenIDs.insert(announcement.id)
                uniqueAnnouncements.append(announcement)
            } else {
                duplicatesRemoved += 1
            }
        }

        if duplicatesRemoved > 0 {
            print("Removed \(duplicatesRemoved) duplicate announcements")
        }

        return uniqueAnnouncements
    }

    private func deduplicateAssignments(_ assignments: [Assignment]) -> [Assignment] {
        var seenIDs = Set<String>()
        var uniqueAssignments: [Assignment] = []
        var duplicatesRemoved = 0

        for assignment in assignments {
            if !seenIDs.contains(assignment.id) {
                seenIDs.insert(assignment.id)
                uniqueAssignments.append(assignment)
            } else {
                duplicatesRemoved += 1
            }
        }

        if duplicatesRemoved > 0 {
            print("Removed \(duplicatesRemoved) duplicate assignments")
        }

        return uniqueAssignments
    }

    // MARK: - Error Handling

    private func handleError(
        _ error: Error, context: String, response: HTTPURLResponse? = nil, data: Data? = nil
    ) {
        // First check if it's a URLError (network timeout, no connection, etc.)
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                errorMessage = "Timeout: The request timed out. Please try again."
            case .notConnectedToInternet:
                errorMessage = "No Internet Connection: Please check your network settings."
            case .cannotFindHost:
                errorMessage = "Cannot Find Host: The server could not be reached."
            default:
                errorMessage = "Network Error: \(urlError.localizedDescription)"
            }
            return
        }

        // Check for server error with JSON error message
        if let httpResponse = response, httpResponse.statusCode >= 400 {
            if let data = data,
                let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let serverError = errorDict["error"] as? String
            {
                // Server returned an error message in JSON
                errorMessage = "Server Error: \(serverError)"
            } else {
                // Generic server error
                errorMessage = "Server Error: HTTP \(httpResponse.statusCode)"
            }
            return
        }

        // JSON decoding error
        if error is DecodingError {
            errorMessage = "Data Error: Failed to parse server response."
            return
        }

        // Generic error
        errorMessage = "\(context): \(error.localizedDescription)"
    }
}
