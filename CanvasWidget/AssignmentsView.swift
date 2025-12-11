//
//  AssignmentsView.swift
//  CanvasWidget
//
//  Created by Claude on 12/10/25.
//

import SwiftUI

struct AssignmentsView: View {
    @StateObject private var provider = Provider.shared
    @State private var assignments = sampleAssignments()
    
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.rectangle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("Assignments")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("View your Canvas assignments here")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing) {
                    Button(action: {
                        Task {
                            await provider.fetchAssignments()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                    }
                    .disabled(provider.isLoadingAssignments)
                    .padding()
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        if isHovering && !provider.isLoadingAssignments {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                }
                
                // List
                ScrollView {
                    LazyVStack(spacing: 6) {
                        let currentAssignments = provider.assignments.isEmpty ? assignments : provider.assignments
                        ForEach(currentAssignments) { assignment in
                            assignmentRow(for: assignment)
                            
                            if assignment.id != currentAssignments.last?.id {
                                Divider()
                                    .padding(.vertical, 1)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .disabled(provider.isLoadingAssignments)
            .blur(radius: provider.isLoadingAssignments ? 2 : 0)
            
            // Blocking Modal Progress Overlay
            if provider.isLoadingAssignments {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                    
                    Text("Loading Assignments...")
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
    
    private func assignmentRow(for assignment: Assignment) -> some View {
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
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            print("Tapped assignment: \(assignment.title)")
        }
    }
}

#Preview {
    AssignmentsView()
}
