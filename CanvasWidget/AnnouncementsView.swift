//
//  AnnouncementsView.swift
//  CanvasWidget
//
//  Created by Claude on 12/10/25.
//

import SwiftUI
import AppKit

struct AnnouncementsView: View {
    @StateObject private var provider = Provider.shared
    @State private var announcements = sampleAnnouncements()
    @State private var showingLinkAlert = false
    @State private var linkToOpen: URL?
    
    var body: some View {
        ZStack{
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
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing) {
                    Button(action: {
                        Task {
                            await provider.fetchAnnouncements()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                    }
                    .disabled(provider.isLoadingAnnouncements)
                    .padding()
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        if isHovering && !provider.isLoadingAnnouncements {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                }
                
                // List
                ScrollView {
                    LazyVStack(spacing: 6) {
                        let currentAnnouncements = provider.announcements.isEmpty ? announcements : provider.announcements
                        ForEach(currentAnnouncements) { announcement in
                            announcementRow(for: announcement)
                            
                            if announcement.id != currentAnnouncements.last?.id {
                                Divider()
                                    .padding(.vertical, 1)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .disabled(provider.isLoadingAnnouncements)
            .blur(radius: provider.isLoadingAnnouncements ? 2 : 0)
            
            // Blocking Modal Progress Overlay
            if provider.isLoadingAnnouncements {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                    
                    Text("Loading Announcements...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.windowBackgroundColor))
                        .shadow(radius: 20)
                )
            }
        }
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
            linkToOpen = announcement.link
            showingLinkAlert = true
        }
        .alert("Open in Browser?", isPresented: $showingLinkAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open") {
                if let link = linkToOpen {
                    NSWorkspace.shared.open(link)
                }
            }
        } message: {
            Text("Do you want to open this link in your default browser?")
        }
    }
}

#Preview {
    AnnouncementsView()
}
