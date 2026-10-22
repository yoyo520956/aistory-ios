import SwiftUI

struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let onAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2)
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let actionTitle, let onAction {
                Button(action: onAction) {
                    Text(actionTitle)
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.aiPrimary)
                        .cornerRadius(10)
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 32)
    }
}

struct LoadingState: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
