//
//  Provider.swift
//  CanvasWidget
//
//  Created by Claude on 12/10/25.
//

import Foundation
import Combine

@MainActor
class Provider: ObservableObject {
    static let shared = Provider()

    @Published var announcements: [Announcement] = []
    @Published var assignments: [Assignment] = []
    @Published var isLoadingAnnouncements = false
    @Published var isLoadingAssignments = false

    private let defaults = UserDefaults(suiteName: "group.com.custom.CanvasWidget") ?? .standard
    private let announcementsKey = "CachedAnnouncements"
    private let assignmentsKey = "CachedAssignments"

    private init() {
        loadCachedData()
    }

    func fetchAnnouncements() async {
        isLoadingAnnouncements = true

        // Get settings from UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.custom.CanvasWidget") ?? .standard
        guard let scraperAPIUrl = defaults.string(forKey: "ScraperAPIUrl"),
              let sessionId = defaults.string(forKey: "SessionID"),
              !scraperAPIUrl.isEmpty,
              !sessionId.isEmpty else {
            isLoadingAnnouncements = false
            print("Missing scraper API URL or session ID")
            return
        }

        // Create URL
        guard let url = URL(string: "\(scraperAPIUrl)/announcements") else {
            isLoadingAnnouncements = false
            print("Invalid announcements URL")
            return
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionId)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                isLoadingAnnouncements = false
                print("Failed to fetch announcements. Status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return
            }

            // Parse JSON response
            let decodedAnnouncements = try JSONDecoder().decode([Announcement].self, from: data)
            let uniqueAnnouncements = deduplicateAnnouncements(decodedAnnouncements)
            self.announcements = uniqueAnnouncements
            saveAnnouncementsToCache(uniqueAnnouncements)
            print("Successfully fetched \(decodedAnnouncements.count) announcements (\(uniqueAnnouncements.count) unique)")

        } catch {
            isLoadingAnnouncements = false
            print("Error fetching announcements: \(error)")
        }

        isLoadingAnnouncements = false
    }

    func fetchAssignments() async {
        isLoadingAssignments = true

        // Get settings from UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.custom.CanvasWidget") ?? .standard
        guard let scraperAPIUrl = defaults.string(forKey: "ScraperAPIUrl"),
              let sessionId = defaults.string(forKey: "SessionID"),
              !scraperAPIUrl.isEmpty,
              !sessionId.isEmpty else {
            isLoadingAssignments = false
            print("Missing scraper API URL or session ID")
            return
        }

        // Create URL
        guard let url = URL(string: "\(scraperAPIUrl)/assignments") else {
            isLoadingAssignments = false
            print("Invalid assignments URL")
            return
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionId)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                isLoadingAssignments = false
                print("Failed to fetch assignments. Status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return
            }

            // Parse JSON response
            let decodedAssignments = try JSONDecoder().decode([Assignment].self, from: data)
            let uniqueAssignments = deduplicateAssignments(decodedAssignments)
            self.assignments = uniqueAssignments
            saveAssignmentsToCache(uniqueAssignments)
            print("Successfully fetched \(decodedAssignments.count) assignments (\(uniqueAssignments.count) unique)")

        } catch {
            isLoadingAssignments = false
            print("Error fetching assignments: \(error)")
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
}
