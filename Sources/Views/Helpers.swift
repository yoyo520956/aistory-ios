import UIKit
import SwiftUI

// MARK: - Bridge View Controller for AVPlayer

struct AVPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.videoGravity = .resizeAspect
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

// MARK: - Project Row (for table/list views)

struct ProjectRow: View {
    let project: Project
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.displayName.isEmpty ? project.name : project.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(project.originalTopic.prefix(40))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text("\(project.progressPercentage)%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.aiPrimary)
        }
        .padding(.vertical, 8)
    }
}
