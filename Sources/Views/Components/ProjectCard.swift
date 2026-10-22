import SwiftUI

// MARK: - Project Card

struct ProjectCard: View {
    let project: Project
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 左侧状态指示
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(project.isCompleted ? Color.aiSuccess : project.isProcessing ? Color.aiWarning : Color.aiSurface)
                        .frame(width: 48, height: 48)
                    Image(systemName: project.isCompleted ? "checkmark.circle.fill" : project.isProcessing ? "play.circle.fill" : "film.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(project.isCompleted ? .white : project.isProcessing ? .orange : .secondary)
                }
                
                // 内容区
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.displayName.isEmpty ? project.name : project.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        if let ep = project.episodeTitle, !ep.isEmpty {
                            Text(ep)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !project.originalTopic.isEmpty {
                        Text(truncate(project.originalTopic, length: 60))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    HStack(spacing: 8) {
                        StageBadge(status: project.statusDisplay)
                        if project.stagesCount > 0 {
                            Text("\(project.completedStagesCount)/\(project.stagesCount)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(formatDate(project.createdAt))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.aiSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.aiBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func truncate(_ s: String, length: Int) -> String {
        s.count > length ? String(s.prefix(length)) + "…" : s
    }
    
    private func formatDate(_ s: String) -> String {
        guard let d = ISO8601DateFormatter().date(from: s) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f.string(from: d)
    }
}

// MARK: - Stage Badge

struct StageBadge: View {
    let status: String
    
    var color: Color {
        switch status.lowercased() {
        case "completed", "成功": return .aiSuccess
        case "processing", "running", "处理中": return .aiWarning
        case "failed", "失败": return .aiError
        default: return .secondary
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}
