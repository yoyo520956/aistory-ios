import SwiftUI

struct ProjectDetailScreen: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var executingStage: String?
    @State private var errorMessage: String?
    
    var project: Project? { appState.selectedProject }
    
    private let stages = [
        ("rewrite", "文案改写", "pencil"),
        ("storyboard", "分镜设计", "viewfinder"),
        ("image_generation", "图片生成", "photo"),
        ("camera_movement", "运镜规划", "play.circle"),
        ("video_generation", "视频合成", "film")
    ]
    
    var body: some View {
        Group {
            if let project {
                DetailContent(project: project, stages: stages, executing: $executingStage, error: $errorMessage)
            } else {
                EmptyState(icon: "exclamationmark.triangle", title: "项目不存在", subtitle: "")
            }
        }
        .navigationTitle(project?.displayName ?? "项目详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } } }
        .alert("执行失败", isPresented: .constant(errorMessage != nil)) {
            Button("重试") { if let s = executingStage { Task { await runStage(s) } } }
            Button("取消", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        .task(id: project?.id) { if let id = project?.id { await appState.refreshProject(id) } }
    }
    
    private func runStage(_ key: String) async {
        guard let id = project?.id else { return }
        executingStage = key; errorMessage = nil
        defer { executingStage = nil }
        do {
            _ = try await APIClient.shared.executeStage(projectId: id, stageName: key)
            await appState.refreshProject(id)
        } catch { errorMessage = error.localizedDescription }
    }
}

// MARK: - 拆分后的子视图（防编译器超时）

struct DetailContent: View {
    let project: Project
    let stages: [(String, String, String)]
    @Binding var executingStage: String?
    @Binding var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                OverviewCard(project: project)
                Divider().background(Color.aiBorder).padding(.horizontal)
                ProjectInfoSection(project: project)
                StageListSection(stages: stages, executingStage: $executingStage, runStage: runStage)
                AssetsSection(project: project)
                Spacer(minLength: 32)
            }
            .background(Color.aiBg)
        }
    }
    
    private func runStage(_ key: String) async {
        guard let id = project.id else { return }
        executingStage = key; errorMessage = nil
        defer { executingStage = nil }
        do {
            _ = try await APIClient.shared.executeStage(projectId: id, stageName: key)
        } catch { errorMessage = error.localizedDescription }
    }
}

struct ProjectInfoSection: View {
    let project: Project
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("项目信息").font(.headline).padding(.horizontal).padding(.top, 12)
            infoRow("原始主题", project.originalTopic.isEmpty ? "—" : project.originalTopic)
            if let ep = project.episodeTitle, !ep.isEmpty { infoRow("分集标题", ep) }
            if let series = project.seriesName, !series.isEmpty { infoRow("所属系列", series) }
        }
        .padding(.vertical, 8)
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
        .padding(.horizontal)
    }
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 72, alignment: .leading)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(.primary).lineLimit(3)
        }
        .padding(.horizontal).padding(.vertical, 6)
    }
}

struct StageListSection: View {
    let stages: [(String, String, String)]
    @Binding var executingStage: String?
    let runStage: (String) async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("生成阶段").font(.headline).padding(.horizontal).padding(.top, 12)
            VStack(spacing: 0) {
                ForEach(Array(stages.enumerated()), id: \.element.0) { i, item in
                    let (key, name, icon) = item
                    StageRow(stageKey: key, stageName: name, icon: icon, executing: executingStage == key) {
                        await runStage(key)
                    }
                    if i < stages.count - 1 {
                        Divider().background(Color.aiBorder)
                    }
                }
            }
            .background(Color.aiSurface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
            .padding(.horizontal)
        }
    }
}

struct OverviewCard: View {
    let project: Project
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.displayName.isEmpty ? project.name : project.displayName)
                        .font(.title3).fontWeight(.semibold)
                    Text(project.statusDisplay).font(.caption).foregroundStyle(projectStatusColor)
                }
                Spacer()
                Text("\(project.progressPercentage)%").font(.title3).fontWeight(.bold).foregroundStyle(Color.aiPrimary)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.aiBorder)
                    Rectangle().fill(LinearGradient(colors: [Color.aiPrimary, Color.aiSuccess], startPoint: .leading, endPoint: .trailing))
                        .frame(width: g.size.width * CGFloat(project.progressPercentage) / 100)
                }.cornerRadius(4).frame(height: 6)
            }
            HStack {
                Text("已完成 \(project.completedStagesCount)/\(project.stagesCount) 阶段").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(project.createdAt).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.aiSurface).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
        .padding()
    }
    private var projectStatusColor: Color {
        switch project.status.lowercased() {
        case "completed": return .aiSuccess
        case "processing", "running": return .aiWarning
        case "failed": return .aiError
        default: return .secondary
        }
    }
}

struct StageRow: View {
    let stageKey: String
    let stageName: String
    let icon: String
    let executing: Bool
    let onExecute: () async -> Void
    
    var body: some View {
        Button { Task { await onExecute() } } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title3).foregroundStyle(stageIconColor).frame(width: 28)
                Text(stageName).font(.body).foregroundStyle(.primary)
                Spacer()
                if executing { ProgressView().scaleEffect(0.8) }
                else { Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary) }
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    private var stageIconColor: Color {
        switch stageKey {
        case "rewrite": return .purple
        case "storyboard": return .blue
        case "image_generation": return .orange
        case "camera_movement": return .cyan
        case "video_generation": return .red
        default: return .secondary
        }
    }
}

struct AssetsSection: View {
    let project: Project
    @State private var images: [GeneratedImage] = []
    @State private var loading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("生成素材").font(.headline).padding(.horizontal)
            if images.isEmpty && !loading {
                Text("暂无素材，请先完成图片生成阶段").font(.caption).foregroundStyle(.secondary).padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(images) { img in
                            AsyncImage(url: URL(string: img.imageUrl)) { phase in
                                switch phase {
                                case .success(let i): i.resizable().aspectRatio(contentMode: .fill).frame(width: 100, height: 100).cornerRadius(8)
                                case .failure: RoundedRectangle(cornerRadius: 8).fill(Color.aiBorder).frame(width: 100, height: 100).overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                                case .empty: RoundedRectangle(cornerRadius: 8).fill(Color.aiSurface).frame(width: 100, height: 100).overlay(ProgressView())
                                @unknown default: EmptyView()
                                }
                            }
                        }
                    }.padding()
                }
            }
        }
        .padding(.horizontal)
        .task {
            loading = true; defer { loading = false }
            images = (try? await APIClient.shared.fetchImages(projectId: project.id)) ?? []
        }
    }
}
