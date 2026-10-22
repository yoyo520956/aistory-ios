import SwiftUI

struct ProjectDetailScreen: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var executingStage: String?
    @State private var errorMessage: String?
    
    var project: Project? { appState.selectedProject }
    
    private let stages = [
        ("rewrite", "文案改写"),
        ("storyboard", "分镜设计"),
        ("image_generation", "图片生成"),
        ("camera_movement", "运镜规划"),
        ("video_generation", "视频合成")
    ]
    
    var body: some View {
        Group {
            if let project {
                ScrollView {
                    VStack(spacing: 0) {
                        OverviewCard(project: project)
                        
                        Divider().background(Color.aiBorder).padding(.horizontal)
                        
                        // 项目信息
                        VStack(alignment: .leading, spacing: 10) {
                            Text("项目信息").font(.headline).padding(.horizontal).padding(.top, 12)
                            infoItem("原始主题", project.originalTopic.isEmpty ? "—" : project.originalTopic)
                            if let ep = project.episodeTitle, !ep.isEmpty {
                                infoItem("分集标题", ep)
                            }
                            if let series = project.seriesName, !series.isEmpty {
                                infoItem("所属系列", series)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color.aiSurface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
                        .padding(.horizontal)
                        
                        // 阶段
                        VStack(alignment: .leading, spacing: 10) {
                            Text("生成阶段").font(.headline).padding(.horizontal).padding(.top, 12)
                            VStack(spacing: 0) {
                                ForEach(Array(stages.enumerated()), id: \.element.0) { i, item in
                                    let (key, name) = item
                                    StageRow(stageKey: key, stageName: name, executing: executingStage == key) {
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
                        
                        // 素材区
                        AssetsSection(project: project)
                        
                        Spacer(minLength: 32)
                    }
                    .background(Color.aiBg)
                }
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
    
    private func infoItem(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 72, alignment: .leading)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(.primary).lineLimit(3)
        }
        .padding(.horizontal).padding(.vertical, 6)
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
            }.frame(height: 6)
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
                                Group {
                                    switch phase {
                                    case .success(let i): i.resizable().aspectRatio(contentMode: .fill).frame(width: 100, height: 100).cornerRadius(8)
                                    case .failure: RoundedRectangle(cornerRadius: 8).fill(Color.aiBorder).frame(width: 100, height: 100).overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                                    case .empty: RoundedRectangle(cornerRadius: 8).fill(Color.aiSurface).frame(width: 100, height: 100).overlay(ProgressView())
                                    @unknown default: EmptyView()
                                    }
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
            if let id = project.id { images = (try? await APIClient.shared.fetchImages(projectId: id)) ?? [] }
        }
    }
}
