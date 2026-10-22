import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    
    var body: some View {
        VideoPlayer(player: AVPlayer(url: url))
            .aspectRatio(contentMode: .fit)
            .cornerRadius(8)
    }
}

struct ProjectRow: View {
    let project: Project
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.displayName.isEmpty ? project.name : project.displayName)
                    .font(.body).fontWeight(.medium).foregroundStyle(.primary)
                Text(project.originalTopic.prefix(40))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text("\(project.progressPercentage)%")
                .font(.caption).fontWeight(.semibold).foregroundStyle(Color.aiPrimary)
        }
        .padding(.vertical, 8)
    }
}
