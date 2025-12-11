//
//  AnnouncementsView.swift
//  CanvasWidget
//
//  Created by Claude on 12/10/25.
//

import SwiftUI

struct AnnouncementsView: View {
    private let announcements = sampleAnnouncements()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)

                Text("Announcements")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("View your Canvas announcements here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            // List
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(announcements) { announcement in
                        announcementRow(for: announcement)

                        if announcement.id != announcements.last?.id {
                            Divider()
                                .padding(.vertical, 1)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func announcementRow(for announcement: Announcement) -> some View {
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
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            print("Tapped announcement: \(announcement.title)")
        }
    }
}

#Preview {
    AnnouncementsView()
}