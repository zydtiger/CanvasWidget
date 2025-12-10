//
//  WidgetExtension.swift
//  WidgetExtension
//
//  Created by Zhiyuan Ding on 11/30/25.
//

import WidgetKit
import SwiftUI

struct Announcement: Identifiable {
    let id = UUID()
    let date: String
    let title: String
    let course: String
    let link: URL
}

struct Assignment: Identifiable {
    let id = UUID()
    let course: String
    let title: String
    let dueDate: String
    let link: URL
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let announcements: [Announcement]
    let assignments: [Assignment]
}

func sampleAnnouncements() -> [Announcement] {
    return [
        Announcement(
            date: "Dec 9 at 6:49pm",
            title: "Assignment Due Tomorrow",
            course: "CS 101",
            link: URL(string: "https://canvas.example.com/courses/1/assignments/1")!
        ),
        Announcement(
            date: "Dec 9 at 6:49pm",
            title: "New Reading Material Posted",
            course: "Math 205",
            link: URL(string: "https://canvas.example.com/courses/2/pages/reading")!
        ),
        Announcement(
            date: "Dec 9 at 6:49pm",
            title: "Office Hours Changed",
            course: "Physics 301",
            link: URL(string: "https://canvas.example.com/courses/3/discussion_topics/1")!
        ),
        Announcement(
            date: "Dec 9 at 6:49pm",
            title: "Midterm Exam Scheduled",
            course: "History 150",
            link: URL(string: "https://canvas.example.com/courses/4/quizzes/1")!
        ),
        Announcement(
            date: "Dec 9 at 6:49pm",
            title: "Lab Report Due Friday",
            course: "Chemistry 220",
            link: URL(string: "https://canvas.example.com/courses/5/assignments/2")!
        ),
        Announcement(
            date: "Dec 9 at 6:49pm",
            title: "Group Project Guidelines",
            course: "English 305",
            link: URL(string: "https://canvas.example.com/courses/6/assignments/3")!
        )
    ]
}

func sampleAssignments() -> [Assignment] {
    return [
        Assignment(
            course: "EN.580.680.01.FA25",
            title: "Assignment Created - Teammate Evaluation Form, Precision Care Medicine",
            dueDate: "Dec 15 by 9pm",
            link: URL(string: "https://jhu.instructure.com/courses/102501/announcements/1142916")!
        ),
        Assignment(
            course: "CS 101",
            title: "Homework 1",
            dueDate: "Dec 12 by 11:59pm",
            link: URL(string: "https://canvas.example.com/courses/1/assignments/101")!
        ),
        Assignment(
            course: "Math 205",
            title: "Problem Set 3",
            dueDate: "Dec 14 by 5pm",
            link: URL(string: "https://canvas.example.com/courses/2/assignments/201")!
        )
    ]
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
