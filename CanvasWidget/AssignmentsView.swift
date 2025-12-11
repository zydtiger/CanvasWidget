//
//  AssignmentsView.swift
//  CanvasWidget
//
//  Created by Claude on 12/10/25.
//

import SwiftUI

struct AssignmentsView: View {
    private let assignments = sampleAssignments()

    var body: some View {
        VStack(spacing: 0) {
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

            // List
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(assignments) { assignment in
                        assignmentRow(for: assignment)

                        if assignment.id != assignments.last?.id {
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