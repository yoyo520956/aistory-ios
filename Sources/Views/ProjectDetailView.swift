import SwiftUI

struct ProjectDetailView: View {
    let projectId: UUID
    @EnvironmentObject var projectStore: ProjectStore
    @Environment(\.dismiss) private var dismiss
    @State private var project: Project?
    @State private var stages: [ProjectStage] = []
    @State private var executingStage: String?
    @State private var showError = false
    @State private var showingEdit = false
    @State private var stageProgress: [String: Double] = [:]
    
    var body: some View {
        Group {
            if let project = project {
                ScrollView {
                    VStack(spacing: 0) {
                        // Overview Card
                        OverviewCard(project: project)
                            .padding()
                        
                        Divider().background(Color.aiBorder)
                        
                        // Project Info
                        ProjectInfoSection(project: project)
                            .padding()
                        
                        Divider().background(Color.aiBorder)
                        
                        // Stage Execution
                        StageExecutionSection(
                            stages: stages,
                            executingStage: $executingStage,
                            stageProgress: stageProgress
                        )
                        .padding()
                        
                        // Assets Preview (placeholder for now)
                        AssetsSection(project: project)
                            .padding()
                        
                        Spacer(minLength: 20)
                    }
                    .background(Color.aiBg)
                }
                .navigationTitle(project.displayName.isEmpty ? project.name : project.displayName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingEdit = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
                .sheet(isPresented: $showingEdit) {
                    ProjectEditView(project: project)
                }
                .task { await loadProject() }
                .alert("错误", isPresented: $showError) {
                    Button("重试") {
                        if let s = executingStage {
                            Task { await executeStage(s) }
                        }
                    }
                    Button("取消", role: .cancel) { showError = false }
                } message: {
                    Text(projectStore.lastError ?? "")
                }
            } else {
                ProgressView().task { await loadProject() }
            }
        }
    }
    
    private func loadProject() async {
        do {
            let p = try await APIClient.shared.fetchProject(id: projectId)
            project = p
            let s = try await APIClient.shared.fetchStages(projectId: projectId)
            stages = s
        } catch {
            projectStore.lastError = error.localizedDescription
            showError = true
        }
    }
    
    private func executeStage(_ stageName: String) async {
        guard let project = project else { return }
        executingStage = stageName
        stageProgress[stageName] = 0
        defer { executingStage = nil }
        
        do {
            try await projectStore.executeStage(projectId: project.id, stageName: stageName)
            await loadProject()
        } catch {
            projectStore.lastError = error.localizedDescription
            showError = true
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
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.aiText1)
                    
                    HStack {
                        StatusBadge(status: project.status)
                        if let series = project.seriesName, !series.isEmpty {
                            Text("•")
                                .foregroundStyle(Color.aiText2)
                            Text(series)
                                .font(.caption)
                                .foregroundStyle(Color.aiText2)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(project.progressPercentage))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(projectStatusColor)
                    Text(project.statusDisplay)
                        .font(.caption)
                        .foregroundStyle(Color.aiText2)
                }
            }
            
            // Progress bar
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.aiBorder)
                    Rectangle()
                        .fill(LinearGradient(colors: [Color.aiPrimary, Color.aiSuccess], startPoint: .leading, endPoint: .trailing))
                        .frame(width: g.size.width * CGFloat(project.progressPercentage) / 100)
                }
                .cornerRadius(4)
                .frame(height: 6)
            }
            
            HStack {
                Text("已完成 \(project.completedStagesCount)/\(project.stagesCount) 阶段")
                    .font(.caption)
                    .foregroundStyle(Color.aiText2)
                Spacer()
                Text(formatDate(project.createdAt))
                    .font(.caption2)
                    .foregroundStyle(Color.aiText2)
            }
        }
        .padding()
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }
    
    private var projectStatusColor: Color {
        switch project.status {
        case "completed": return Color.aiSuccess
        case "processing", "queued": return Color.aiWarning
        case "failed": return Color.aiError
        default: return Color.aiText2
        }
    }
    
    private func formatDate(_ date: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        if let d = formatter.date(from: date) {
            return formatter.string(from: d)
        }
        return date
    }
}

struct ProjectInfoSection: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("项目信息").font(.headline).foregroundStyle(Color.aiText1)
            
            InfoRow(label: "原始主题", value: project.originalTopic)
            if let ep = project.episodeTitle, !ep.isEmpty {
                InfoRow(label: "分集标题", value: ep)
            }
            if let series = project.seriesName, !series.isEmpty {
                InfoRow(label: "所属系列", value: series)
            }
            if let screenplayId = project.screenplayId {
                InfoRow(label: "剧本 ID", value: screenplayId.uuidString)
            }
        }
        .padding()
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label).font(.caption).foregroundStyle(Color.aiText2).frame(width: 70, alignment: .leading)
            Text(value).font(.subheadline).foregroundStyle(Color.aiText1).lineLimit(3)
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct StageExecutionSection: View {
    let stages: [ProjectStage]
    @Binding var executingStage: String?
    let stageProgress: [String: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("生成阶段").font(.headline).foregroundStyle(Color.aiText1)
            
            VStack(spacing: 0) {
                ForEach(StageType.allCases, id: \.self) { stageType in
                    let stage = stages.first { $0.stageType == stageType.rawValue } ?? createEmptyStage(stageType)
                    StageRow(stage: stage, executing: executingStage == stage.stageType)
                    
                    if stageType != StageType.allCases.last {
                        Divider().background(Color.aiBorder)
                    }
                }
            }
            .background(Color.aiSurface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
        }
        .padding()
    }
    
    private func createEmptyStage(_ type: StageType) -> ProjectStage {
        ProjectStage(
            id: UUID(),
            stageType: type.rawValue,
            stageTypeDisplay: type.displayName,
            status: "pending",
            statusDisplay: "待处理",
            inputData: nil,
            outputData: nil,
            retryCount: 0,
            errorMessage: nil,
            startedAt: nil,
            completedAt: nil,
            createdAt: ""
        )
    }
}

struct StageRow: View {
    let stage: ProjectStage
    let executing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: stageTypeIcon)
                .font(.title3)
                .foregroundStyle(stageIconColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(stage.stageTypeDisplay).font(.body).foregroundStyle(Color.aiText1)
                Text(stage.statusDisplay).font(.caption).foregroundStyle(stageStatusColor)
            }
            
            Spacer()
            
            if executing {
                ProgressView().scaleEffect(0.8)
            } else {
                switch stage.status {
                case "completed":
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.aiSuccess)
                case "failed":
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.aiError)
                default:
                    Button("执行") {
                        // This will trigger the parent's executeStage
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(stageIconColor)
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    private var stageTypeIcon: String {
        StageType(rawValue: stage.stageType)?.iconName ?? "circle"
    }
    
    private var stageIconColor: Color {
        StageType(rawValue: stage.stageType)?.iconColor ?? .secondary
    }
    
    private var stageStatusColor: Color {
        switch stage.status {
        case "completed": return Color.aiSuccess
        case "failed": return Color.aiError
        case "processing": return Color.aiWarning
        default: return Color.aiText2
        }
    }
}

struct AssetsSection: View {
    let project: Project
    @State private var images: [String] = []
    @State private var videos: [String] = []
    @State private var loading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("生成素材").font(.headline).foregroundStyle(Color.aiText1)
            
            if images.isEmpty && videos.isEmpty && !loading {
                Text("完成图片生成阶段后可预览素材")
                    .font(.caption)
                    .foregroundStyle(Color.aiText2)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(images, id: \.self) { url in
                            AsyncImage(url: URL(string: url)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fill).frame(width: 100, height: 100).cornerRadius(8)
                                case .failure:
                                    RoundedRectangle(cornerRadius: 8).fill(Color.aiBorder).frame(width: 100, height: 100).overlay(Image(systemName: "photo").foregroundStyle(Color.aiText2))
                                case .empty:
                                    RoundedRectangle(cornerRadius: 8).fill(Color.aiSurface).frame(width: 100, height: 100).overlay(ProgressView())
                                @unknown default: EmptyView()
                                }
                            }
                        }
                    }.padding()
                }
            }
        }
        .padding()
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }
}
