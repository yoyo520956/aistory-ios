import SwiftUI
import AVKit

// MARK: - 概览卡片

struct OverviewCard: View {
    let project: Project

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.displayName.isEmpty ? project.name : project.displayName)
                        .font(.title3).fontWeight(.semibold)
                        .foregroundStyle(Color.aiText1)
                    HStack(spacing: 6) {
                        StatusBadge(status: project.status)
                        if let series = project.seriesName, !series.isEmpty {
                            Text("·  \(series)")
                                .font(.caption).foregroundStyle(Color.aiText2)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(project.progressPercentage))%")
                        .font(.title2).fontWeight(.bold)
                        .foregroundStyle(statusColor)
                    Text(project.statusDisplay)
                        .font(.caption).foregroundStyle(Color.aiText2)
                }
            }

            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.aiBorder)
                    Rectangle()
                        .fill(LinearGradient(colors: [Color.aiPrimary, Color.aiSuccess],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: g.size.width * CGFloat(project.progressPercentage) / 100)
                }
                .cornerRadius(4).frame(height: 6)
            }

            HStack {
                Text("已完成 \(project.completedStagesCount)/\(project.stagesCount) 阶段")
                    .font(.caption).foregroundStyle(Color.aiText2)
                Spacer()
                Text(project.createdAt.isEmpty ? "-" : project.createdAt)
                    .font(.caption2).foregroundStyle(Color.aiText2)
            }
        }
        .padding()
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }

    private var statusColor: Color {
        switch project.status {
        case "completed": return Color.aiSuccess
        case "processing", "queued": return Color.aiWarning
        case "failed": return Color.aiError
        default: return Color.aiPrimary
        }
    }
}

// MARK: - 项目信息

struct ProjectInfoSection: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("项目信息").font(.headline).foregroundStyle(Color.aiText1)
            LabeledRow(label: "主题", value: project.originalTopic.isEmpty ? "-" : project.originalTopic)
            if let ep = project.episodeTitle, !ep.isEmpty {
                LabeledRow(label: "分集标题", value: ep)
            }
            if let series = project.seriesName, !series.isEmpty {
                LabeledRow(label: "所属作品", value: series)
            }
            if let desc = project.descriptionOrNil {
                LabeledRow(label: "描述", value: desc)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }
}

extension Project {
    var descriptionOrNil: String? {
        description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description
    }
}

// MARK: - 阶段执行

struct StageExecutionSection: View {
    let stages: [ProjectStage]
    let executingStage: String?
    let onExecute: (String) -> Void
    let onRetry: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("生成阶段").font(.headline).foregroundStyle(Color.aiText1)
                Spacer()
                Text("\(stages.filter { $0.status == "completed" }.count)/\(StageType.allCases.count)")
                    .font(.caption).foregroundStyle(Color.aiText2)
            }

            VStack(spacing: 0) {
                ForEach(Array(StageType.allCases.enumerated()), id: \.element.id) { index, stageType in
                    let stage = stages.first { $0.stageType == stageType.rawValue }
                    StageRowView(stageType: stageType,
                                 stage: stage,
                                 isExecuting: executingStage == stageType.rawValue,
                                 onExecute: { onExecute(stageType.rawValue) },
                                 onRetry: { onRetry(stageType.rawValue) })
                    if index < StageType.allCases.count - 1 {
                        Divider().background(Color.aiBorder)
                    }
                }
            }
            .background(Color.aiSurface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
        }
    }
}

struct StageRowView: View {
    let stageType: StageType
    let stage: ProjectStage?
    let isExecuting: Bool
    let onExecute: () -> Void
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: stageType.iconName)
                .font(.title3)
                .foregroundStyle(statusColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(stageType.displayName)
                    .font(.body).foregroundStyle(Color.aiText1)
                Text(statusText)
                    .font(.caption).foregroundStyle(statusColor)
            }

            Spacer()

            if isExecuting {
                ProgressView().scaleEffect(0.8)
            } else if isFailed {
                Button {
                    onRetry()
                } label: {
                    Label("重试", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.aiError)
            } else if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.aiSuccess)
            } else {
                Button {
                    onExecute()
                } label: {
                    Text("执行").font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(stageType.iconColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private var status: String { stage?.status ?? "pending" }

    private var isCompleted: Bool { status == "completed" }
    private var isFailed: Bool { status == "failed" }

    private var statusText: String {
        switch status {
        case "completed": return "已完成"
        case "failed": return stage?.errorMessage?.isEmpty == false ? "失败：\(stage?.errorMessage ?? "")" : "失败"
        case "processing": return "处理中…"
        case "skipped": return "已跳过"
        case "queued": return "排队中"
        default: return "待执行"
        }
    }

    private var statusColor: Color {
        switch status {
        case "completed": return Color.aiSuccess
        case "failed": return Color.aiError
        case "processing", "queued": return Color.aiWarning
        default: return isExecuting ? stageType.iconColor : Color.aiText2
        }
    }
}

// MARK: - 实时日志

struct LiveLogCard: View {
    @ObservedObject var stream: StageStreamStore
    @Binding var expanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: stream.isStreaming ? "dot.radiowaves.left.and.right" : "text.bubble")
                    .foregroundStyle(stream.isStreaming ? Color.aiSuccess : Color.aiText2)
                Text(stream.activeStage.map { StageType(rawValue: $0)?.displayName ?? $0 } ?? "流水线")
                    .font(.headline).foregroundStyle(Color.aiText1)
                Spacer()
                if stream.isStreaming {
                    ProgressView().scaleEffect(0.7)
                }
                Button(expanded ? "收起" : "展开") {
                    expanded.toggle()
                }
                .font(.caption)
            }

            if expanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        if !stream.latestTokens.isEmpty {
                            Text(trimmedTokens)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(Color.aiText1)
                                .textSelection(.enabled)
                        }
                        ForEach(Array(stream.log.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(line.hasPrefix("✗") ? Color.aiError : Color.aiText2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 260)
            } else {
                Text(lastLine)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color.aiText2)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }

    private var trimmedTokens: String {
        let t = stream.latestTokens
        return t.count > 1200 ? String(t.suffix(1200)) : t
    }

    private var lastLine: String {
        if !stream.latestTokens.isEmpty { return trimmedTokens }
        return stream.log.last ?? ""
    }
}
