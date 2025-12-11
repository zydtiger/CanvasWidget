//
//  AnnouncementsView.swift
//  CanvasWidget
//
//  Created by Claude on 12/10/25.
//

import SwiftUI

struct AnnouncementsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "speaker.wave.2")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Announcements")
                .font(.title)
                .fontWeight(.semibold)

            Text("View your Canvas announcements here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AnnouncementsView()
}