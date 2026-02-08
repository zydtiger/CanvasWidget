//
//  WidgetExtension.swift
//  WidgetExtension
//
//  Created by Zhiyuan Ding on 11/30/25.
//

import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let announcements: [Announcement]
    let assignments: [Assignment]
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            announcements: sampleAnnouncements(),
            assignments: sampleAssignments()
        )
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: configuration,
            announcements: sampleAnnouncements(),
            assignments: sampleAssignments()
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        // Read settings from Shared App Group
        let defaults = UserDefaults(suiteName: "group.com.custom.CanvasWidget")
        let apiUrl = defaults?.string(forKey: "ScraperAPIUrl") ?? "Not set"
        let sessionId = defaults?.string(forKey: "SessionID") ?? "Not set"

        print("WidgetExtension Settings:")
        print("ScraperAPIUrl: \(apiUrl)")
        print("SessionID: \(sessionId)")

        // Generate a single timeline entry for the current date.
        let now = Date()
        let entry = SimpleEntry(
            date: now,
            configuration: configuration,
            announcements: sampleAnnouncements(),
            assignments: sampleAssignments()
        )
        
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: now)!
        return Timeline(entries: [entry], policy: .after(nextRefreshDate))
    }
}

struct WidgetExtensionEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    // MARK: - Size Configuration
    
    var maxItems: Int {
        switch family {
        case .systemSmall:
            return 2
        case .systemMedium:
            return 3
        case .systemLarge, .systemExtraLarge:
            return 6
        default:
            return 3
        }
    }
    
    var contentPadding: CGFloat {
        switch family {
        case .systemSmall:
            return 2
        case .systemMedium:
            return 4
        case .systemLarge, .systemExtraLarge:
            return 5
        default:
            return 5
        }
    }
    
    var itemSpacing: CGFloat {
        switch family {
        case .systemSmall:
            return 3
        case .systemMedium:
            return 2
        case .systemLarge, .systemExtraLarge:
            return 6
        default:
            return 4
        }
    }
    
    var headerSpacing: CGFloat {
        switch family {
        case .systemSmall:
            return 6
        case .systemMedium:
            return 4
        case .systemLarge, .systemExtraLarge:
            return 8
        default:
            return 6
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: headerSpacing) {
            // Header
            Text(headerTitle)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // Content
            contentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(contentPadding)
    }
    
    var headerTitle: String {
        switch entry.configuration.contentType {
        case .announcements:
            return "Announcements"
        case .assignments:
            return "Assignments"
        }
    }
    
    @ViewBuilder
    var contentView: some View {
        switch entry.configuration.contentType {
        case .announcements:
            if entry.announcements.isEmpty {
                emptyStateView(text: "No announcements")
            } else {
                announcementsListView
            }
        case .assignments:
            if entry.assignments.isEmpty {
                emptyStateView(text: "No assignments")
            } else {
                assignmentsListView
            }
        }
    }
    
    // MARK: - Subviews
    
    private func emptyStateView(text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var announcementsListView: some View {
        VStack(alignment: .leading, spacing: itemSpacing) {
            ForEach(Array(entry.announcements.prefix(maxItems))) { announcement in
                announcementRow(for: announcement)
                
                if announcement.id != entry.announcements.prefix(maxItems).last?.id {
                    Divider()
                        .padding(.vertical, 1)
                }
            }
        }
    }
    
    private var assignmentsListView: some View {
        VStack(alignment: .leading, spacing: itemSpacing) {
            ForEach(Array(entry.assignments.prefix(maxItems))) { assignment in
                assignmentRow(for: assignment)
                
                if assignment.id != entry.assignments.prefix(maxItems).last?.id {
                    Divider()
                        .padding(.vertical, 1)
                }
            }
        }
    }
    
    private func announcementRow(for announcement: Announcement) -> some View {
        Link(destination: announcement.link) {
            VStack(alignment: .leading, spacing: 3) {
                Text(announcement.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(announcement.course)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(announcement.date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func assignmentRow(for assignment: Assignment) -> some View {
        Link(destination: assignment.link) {
            VStack(alignment: .leading, spacing: 3) {
                Text(assignment.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(assignment.course)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(assignment.dueDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct WidgetExtension: Widget {
    let kind: String = "WidgetExtension"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WidgetExtensionEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
