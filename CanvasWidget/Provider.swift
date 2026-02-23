//
//  Provider.swift
//  CanvasWidget
//
//  Created by Claude on 12/10/25.
//

import Combine
import Foundation
import UserNotifications

@MainActor
class Provider: ObservableObject {
    static let shared = Provider()

    @Published var announcements: [Announcement] = []
    @Published var assignments: [Assignment] = []
    @Published var hasLoadedAnnouncements = false
    @Published var hasLoadedAssignments = false
    @Published var isLoadingAnnouncements = false
    @Published var isLoadingAssignments = false
    @Published var errorMessage: String?

    private let defaults = UserDefaults(suiteName: "group.com.custom.CanvasWidget") ?? .standard
    private let announcementsKey = "CachedAnnouncements"
    private let assignmentsKey = "CachedAssignments"
    private let announcementsTimestampKey = "CachedAnnouncementsTimestamp"
    private let assignmentsTimestampKey = "CachedAssignmentsTimestamp"
    private let cacheTTL: TimeInterval = 3600  // 1 hour

    // MARK: - URL Fetches

    func fetchAnnouncements(showLoading: Bool = true) async {
        if showLoading {
            isLoadingAnnouncements = true
        }
        errorMessage = nil

        // Get settings from UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.custom.CanvasWidget") ?? .standard
        guard let scraperAPIUrl = defaults.string(forKey: "ScraperAPIUrl"),
            let sessionId = defaults.string(forKey: "SessionID"),
            !scraperAPIUrl.isEmpty,
            !sessionId.isEmpty
        else {
            if showLoading {
                isLoadingAnnouncements = false
            }
            errorMessage = "Missing scraper API URL or session ID in settings"
            return
        }

        // Create URL
        guard let url = URL(string: "\(scraperAPIUrl)/announcements") else {
            if showLoading {
                isLoadingAnnouncements = false
            }
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
                if showLoading {
                    isLoadingAnnouncements = false
                }
                handleError(
                    NSError(
                        domain: "ProviderError", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response"]),
                    context: "Failed to fetch announcements",
                    isBackground: !showLoading)
                return
            }

            guard httpResponse.statusCode == 200 else {
                if showLoading {
                    isLoadingAnnouncements = false
                }
                handleError(
                    NSError(
                        domain: "ProviderError", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "HTTP error"]),
                    context: "Failed to fetch announcements",
                    response: httpResponse,
                    data: data,
                    isBackground: !showLoading)
                return
            }

            // Parse JSON response
            let decodedAnnouncements = try JSONDecoder().decode([Announcement].self, from: data)
            let uniqueAnnouncements = deduplicateAnnouncements(decodedAnnouncements)
            self.announcements = uniqueAnnouncements
            self.hasLoadedAnnouncements = true
            saveAnnouncementsToCache(uniqueAnnouncements)
            print(
                "Successfully fetched \(decodedAnnouncements.count) announcements (\(uniqueAnnouncements.count) unique)"
            )

        } catch {
            if showLoading {
                isLoadingAnnouncements = false
            }
            handleError(error, context: "Failed to fetch announcements", isBackground: !showLoading)
        }

        if showLoading {
            isLoadingAnnouncements = false
        }
    }

    func fetchAssignments(showLoading: Bool = true) async {
        if showLoading {
            isLoadingAssignments = true
        }
        errorMessage = nil

        // Get settings from UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.custom.CanvasWidget") ?? .standard
        guard let scraperAPIUrl = defaults.string(forKey: "ScraperAPIUrl"),
            let sessionId = defaults.string(forKey: "SessionID"),
            !scraperAPIUrl.isEmpty,
            !sessionId.isEmpty
        else {
            if showLoading {
                isLoadingAssignments = false
            }
            errorMessage = "Missing scraper API URL or session ID in settings"
            return
        }

        // Create URL
        guard let url = URL(string: "\(scraperAPIUrl)/assignments") else {
            if showLoading {
                isLoadingAssignments = false
            }
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
                if showLoading {
                    isLoadingAssignments = false
                }
                handleError(
                    NSError(
                        domain: "ProviderError", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response"]),
                    context: "Failed to fetch assignments",
                    isBackground: !showLoading)
                return
            }

            guard httpResponse.statusCode == 200 else {
                if showLoading {
                    isLoadingAssignments = false
                }
                handleError(
                    NSError(
                        domain: "ProviderError", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "HTTP error"]),
                    context: "Failed to fetch assignments",
                    response: httpResponse,
                    data: data,
                    isBackground: !showLoading)
                return
            }

            // Parse JSON response
            let decodedAssignments = try JSONDecoder().decode([Assignment].self, from: data)
            let uniqueAssignments = deduplicateAssignments(decodedAssignments)
            self.assignments = uniqueAssignments
            self.hasLoadedAssignments = true
            saveAssignmentsToCache(uniqueAssignments)
            print(
                "Successfully fetched \(decodedAssignments.count) assignments (\(uniqueAssignments.count) unique)"
            )

        } catch {
            if showLoading {
                isLoadingAssignments = false
            }
            handleError(error, context: "Failed to fetch assignments", isBackground: !showLoading)
        }

        if showLoading {
            isLoadingAssignments = false
        }
    }

    // MARK: - Caching Methods

    private func getCachedAnnouncements() -> (data: [Announcement], isExpired: Bool) {
        guard let data = defaults.data(forKey: announcementsKey) else { return ([], true) }

        let timestamp = defaults.double(forKey: announcementsTimestampKey)
        let isExpired = timestamp == 0 || (Date().timeIntervalSince1970 - timestamp) > cacheTTL

        do {
            return (try JSONDecoder().decode([Announcement].self, from: data), isExpired)
        } catch {
            print("Error decoding cached announcements: \(error)")
            return ([], true)
        }
    }

    private func getCachedAssignments() -> (data: [Assignment], isExpired: Bool) {
        guard let data = defaults.data(forKey: assignmentsKey) else { return ([], true) }

        let timestamp = defaults.double(forKey: assignmentsTimestampKey)
        let isExpired = timestamp == 0 || (Date().timeIntervalSince1970 - timestamp) > cacheTTL

        do {
            return (try JSONDecoder().decode([Assignment].self, from: data), isExpired)
        } catch {
            print("Error decoding cached assignments: \(error)")
            return ([], true)
        }
    }

    // MARK: - Background Refresh

    /// Refreshes announcements in background without blocking UI
    /// - Loads from cache first for immediate display
    /// - Fetches fresh data silently if cache is expired
    func refreshAnnouncementsInBackground() async {
        let (cached, isExpired) = getCachedAnnouncements()

        // Load cached data if it exists (even if empty - empty is valid data)
        if let data = defaults.data(forKey: announcementsKey) {
            self.announcements = cached
            self.hasLoadedAnnouncements = true
            print("Loaded \(cached.count) cached announcements (expired: \(isExpired))")
        }

        // Fetch fresh data silently if expired or no cache exists
        if isExpired {
            await fetchAnnouncements(showLoading: false)
        }
    }

    /// Refreshes assignments in background without blocking UI
    func refreshAssignmentsInBackground() async {
        let (cached, isExpired) = getCachedAssignments()

        // Load cached data if it exists (even if empty - empty is valid data)
        if let data = defaults.data(forKey: assignmentsKey) {
            self.assignments = cached
            self.hasLoadedAssignments = true
            print("Loaded \(cached.count) cached assignments (expired: \(isExpired))")
        }

        // Fetch fresh data silently if expired or no cache exists
        if isExpired {
            await fetchAssignments(showLoading: false)
        }
    }

    // MARK: - Saving to Cache

    private func saveAnnouncementsToCache(_ announcements: [Announcement]) {
        do {
            let data = try JSONEncoder().encode(announcements)
            defaults.set(data, forKey: announcementsKey)
            defaults.set(Date().timeIntervalSince1970, forKey: announcementsTimestampKey)
            print("Saved \(announcements.count) announcements to cache with timestamp")
        } catch {
            print("Error encoding announcements for cache: \(error)")
        }
    }

    private func saveAssignmentsToCache(_ assignments: [Assignment]) {
        do {
            let data = try JSONEncoder().encode(assignments)
            defaults.set(data, forKey: assignmentsKey)
            defaults.set(Date().timeIntervalSince1970, forKey: assignmentsTimestampKey)
            print("Saved \(assignments.count) assignments to cache with timestamp")
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

    // MARK: - Notifications

    /// Sends a macOS notification for background fetch errors
    private func sendNotification(title: String, body: String) {
        let notification = UNMutableNotificationContent()
        notification.title = title
        notification.body = body
        notification.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notification,
            trigger: nil  // Immediate delivery
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    // MARK: - Error Handling

    private func handleError(
        _ error: Error, context: String, response: HTTPURLResponse? = nil, data: Data? = nil,
        isBackground: Bool = false
    ) {
        let message: String

        // First check if it's a URLError (network timeout, no connection, etc.)
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                message = "Timeout: The request timed out. Please try again."
            case .notConnectedToInternet:
                message = "No Internet Connection: Please check your network settings."
            case .cannotFindHost:
                message = "Cannot Find Host: The server could not be reached."
            default:
                message = "Network Error: \(urlError.localizedDescription)"
            }

            // Always set errorMessage for alert dialog
            errorMessage = message

            // Send notification for background errors
            if isBackground {
                sendNotification(title: "CanvasWidget Error", body: message)
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
                message = "Server Error: \(serverError)"
            } else {
                // Generic server error
                message = "Server Error: HTTP \(httpResponse.statusCode)"
            }

            errorMessage = message

            if isBackground {
                sendNotification(title: "CanvasWidget Error", body: message)
            }
            return
        }

        // JSON decoding error
        if error is DecodingError {
            message = "Data Error: Failed to parse server response."
            errorMessage = message

            if isBackground {
                sendNotification(title: "CanvasWidget Error", body: message)
            }
            return
        }

        // Generic error
        message = "\(context): \(error.localizedDescription)"
        errorMessage = message

        if isBackground {
            sendNotification(title: "CanvasWidget Error", body: message)
        }
    }
}
