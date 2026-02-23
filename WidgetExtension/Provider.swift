//
//  Provider.swift
//  WidgetExtension
//
//  Created by Claude on 2/7/26.
//

import Foundation
import UserNotifications

// MARK: - Data Provider for Widget

/// Widget data provider responsible for fetching and caching Canvas data
/// Uses cache-first strategy: always returns cached data immediately, fetches fresh data if expired
@MainActor
struct WidgetDataProvider {

    // MARK: - Constants

    private static let appGroup = "group.com.custom.CanvasWidget"
    private static let announcementsKey = "CachedAnnouncements"
    private static let assignmentsKey = "CachedAssignments"
    private static let announcementsTimestampKey = "CachedAnnouncementsTimestamp"
    private static let assignmentsTimestampKey = "CachedAssignmentsTimestamp"
    private static let urlKey = "ScraperAPIUrl"
    private static let sessionKey = "SessionID"
    private static let cacheTTL: TimeInterval = 3600 // 1 hour

    // MARK: - Refresh (Public API)

    /// Refreshes announcements - loads cache first, fetches from API if expired
    /// - Returns: Cached data (immediate) or fresh data (if fetch succeeds)
    /// - Note: Empty array is valid data (no announcements), only fetch if cache is expired or missing
    static func refreshAnnouncements() async -> [Announcement] {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            print("WidgetProvider: Failed to access App Group defaults")
            return []
        }

        let (cached, isExpired, hasCache) = getCachedAnnouncementsWithExpiry(defaults)

        if hasCache {
            print("WidgetProvider: Loaded \(cached.count) cached announcements (expired: \(isExpired))")
        }

        // Return cached immediately if fresh (even if empty - empty is valid data)
        guard isExpired else {
            return cached
        }

        // Fetch fresh data if expired
        guard let fresh = await fetchAnnouncements(defaults: defaults) else {
            return cached
        }

        return fresh
    }

    /// Refreshes assignments - loads cache first, fetches from API if expired
    /// - Returns: Cached data (immediate) or fresh data (if fetch succeeds)
    /// - Note: Empty array is valid data (no assignments), only fetch if cache is expired or missing
    static func refreshAssignments() async -> [Assignment] {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            print("WidgetProvider: Failed to access App Group defaults")
            return []
        }

        let (cached, isExpired, hasCache) = getCachedAssignmentsWithExpiry(defaults)

        if hasCache {
            print("WidgetProvider: Loaded \(cached.count) cached assignments (expired: \(isExpired))")
        }

        // Return cached immediately if fresh (even if empty - empty is valid data)
        guard isExpired else {
            return cached
        }

        // Fetch fresh data if expired
        guard let fresh = await fetchAssignments(defaults: defaults) else {
            return cached
        }

        return fresh
    }

    // MARK: - Get Cached (Public API - Sync)

    /// Loads cached announcements synchronously without network fetch
    static func getCachedAnnouncements() -> [Announcement] {
        guard let defaults = UserDefaults(suiteName: appGroup) else { return [] }
        return getCachedAnnouncementsWithExpiry(defaults).data
    }

    /// Loads cached assignments synchronously without network fetch
    static func getCachedAssignments() -> [Assignment] {
        guard let defaults = UserDefaults(suiteName: appGroup) else { return [] }
        return getCachedAssignmentsWithExpiry(defaults).data
    }

    // MARK: - Fetch (Private - Network)

    /// Fetches announcements from API and saves to cache
    private static func fetchAnnouncements(defaults: UserDefaults) async -> [Announcement]? {
        guard let (url, sessionId) = getSettings() else {
            sendErrorNotification(title: "CanvasWidget Error", body: "Missing API settings")
            return nil
        }

        guard let apiUrl = URL(string: "\(url)/announcements") else {
            sendErrorNotification(title: "CanvasWidget Error", body: "Invalid API URL")
            return nil
        }

        let result: Result<[Announcement], Error> = await fetchData(from: apiUrl, sessionId: sessionId)

        switch result {
        case .success(let announcements):
            let unique = deduplicate(announcements)
            saveAnnouncementsToCache(defaults, announcements: unique)
            print("WidgetProvider: Fetched \(unique.count) announcements")
            return unique
        case .failure(let error):
            handleFetchError(error, context: "Failed to fetch announcements")
            return nil
        }
    }

    /// Fetches assignments from API and saves to cache
    private static func fetchAssignments(defaults: UserDefaults) async -> [Assignment]? {
        guard let (url, sessionId) = getSettings() else {
            sendErrorNotification(title: "CanvasWidget Error", body: "Missing API settings")
            return nil
        }

        guard let apiUrl = URL(string: "\(url)/assignments") else {
            sendErrorNotification(title: "CanvasWidget Error", body: "Invalid API URL")
            return nil
        }

        let result: Result<[Assignment], Error> = await fetchData(from: apiUrl, sessionId: sessionId)

        switch result {
        case .success(let assignments):
            let unique = deduplicate(assignments)
            saveAssignmentsToCache(defaults, assignments: unique)
            print("WidgetProvider: Fetched \(unique.count) assignments")
            return unique
        case .failure(let error):
            handleFetchError(error, context: "Failed to fetch assignments")
            return nil
        }
    }

    // MARK: - Get Cached with Expiry (Private)

    /// Returns cached announcements, expiry status, and whether cache exists
    /// - Note: Empty array is valid data (no announcements), hasCache=true indicates data was intentionally saved
    private static func getCachedAnnouncementsWithExpiry(_ defaults: UserDefaults) -> (data: [Announcement], isExpired: Bool, hasCache: Bool) {
        guard let data = defaults.data(forKey: announcementsKey),
              let announcements = try? JSONDecoder().decode([Announcement].self, from: data) else {
            return ([], true, false)
        }

        let timestamp = defaults.double(forKey: announcementsTimestampKey)
        let isExpired = timestamp == 0 || (Date().timeIntervalSince1970 - timestamp) > cacheTTL

        return (announcements, isExpired, true)
    }

    /// Returns cached assignments, expiry status, and whether cache exists
    /// - Note: Empty array is valid data (no assignments), hasCache=true indicates data was intentionally saved
    private static func getCachedAssignmentsWithExpiry(_ defaults: UserDefaults) -> (data: [Assignment], isExpired: Bool, hasCache: Bool) {
        guard let data = defaults.data(forKey: assignmentsKey),
              let assignments = try? JSONDecoder().decode([Assignment].self, from: data) else {
            return ([], true, false)
        }

        let timestamp = defaults.double(forKey: assignmentsTimestampKey)
        let isExpired = timestamp == 0 || (Date().timeIntervalSince1970 - timestamp) > cacheTTL

        return (assignments, isExpired, true)
    }

    // MARK: - Save to Cache (Private)

    /// Saves announcements to cache with timestamp
    private static func saveAnnouncementsToCache(_ defaults: UserDefaults, announcements: [Announcement]) {
        do {
            let data = try JSONEncoder().encode(announcements)
            defaults.set(data, forKey: announcementsKey)
            defaults.set(Date().timeIntervalSince1970, forKey: announcementsTimestampKey)
        } catch {
            print("WidgetProvider: Cache encode error - \(error.localizedDescription)")
        }
    }

    /// Saves assignments to cache with timestamp
    private static func saveAssignmentsToCache(_ defaults: UserDefaults, assignments: [Assignment]) {
        do {
            let data = try JSONEncoder().encode(assignments)
            defaults.set(data, forKey: assignmentsKey)
            defaults.set(Date().timeIntervalSince1970, forKey: assignmentsTimestampKey)
        } catch {
            print("WidgetProvider: Cache encode error - \(error.localizedDescription)")
        }
    }

    // MARK: - Network Helpers (Private)

    /// Retrieves API settings from App Group
    private static func getSettings() -> (url: String, sessionId: String)? {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return nil
        }

        guard let url = defaults.string(forKey: urlKey),
              let sessionId = defaults.string(forKey: sessionKey),
              !url.isEmpty,
              !sessionId.isEmpty else {
            return nil
        }

        return (url, sessionId)
    }

    /// Performs API request
    private static func fetchData<T: Decodable>(from url: URL, sessionId: String) async -> Result<T, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionId)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(URLError(.badServerResponse))
            }

            guard httpResponse.statusCode == 200 else {
                print("WidgetProvider: HTTP \(httpResponse.statusCode)")
                return .failure(URLError(.init(rawValue: httpResponse.statusCode)))
            }

            let decoded = try JSONDecoder().decode(T.self, from: data)
            return .success(decoded)

        } catch {
            return .failure(error)
        }
    }

    // MARK: - Utilities (Private)

    /// Removes duplicates based on unique IDs
    private static func deduplicate<T: Identifiable>(_ items: [T]) -> [T] {
        var seen = Set<String>()
        return items.filter { item in
            let id = String(describing: item.id)
            return seen.insert(id).inserted
        }
    }

    // MARK: - Notifications (Private)

    /// Sends a macOS notification for widget fetch errors
    private static func sendErrorNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate delivery
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("WidgetProvider: Failed to send notification - \(error)")
            }
        }
    }

    /// Handles fetch errors with user-friendly messages and notification
    private static func handleFetchError(_ error: Error, context: String) {
        let message: String

        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                message = "Request timed out. Please try again."
            case .notConnectedToInternet:
                message = "No internet connection."
            case .cannotFindHost:
                message = "Cannot reach server."
            default:
                message = urlError.localizedDescription
            }
        } else {
            message = error.localizedDescription
        }

        print("WidgetProvider: \(context) - \(message)")
        sendErrorNotification(title: "CanvasWidget Error", body: "\(context): \(message)")
    }
}
