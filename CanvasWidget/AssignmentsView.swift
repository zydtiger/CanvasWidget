//
//  AssignmentsView.swift
//  CanvasWidget
//
//  Created by Claude on 12/10/25.
//

import SwiftUI

struct AssignmentsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.rectangle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Assignments")
                .font(.title)
                .fontWeight(.semibold)

            Text("View your Canvas assignments here")
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
    AssignmentsView()
}