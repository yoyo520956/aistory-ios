import SwiftUI

struct SeriesDetailView: View {
    let seriesId: UUID
    @EnvironmentObject var projectStore: ProjectStore
    @Environment(\.dismiss) private var dismiss
    @State private var series: Series?
    @State private var episodes: [Project] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var showingCreate = false
    
    var body: some View {
        Group {
            if let series = series {
                List {
                    Section("作品信息") {
                        HStack {
                            Text("名称").foregroundStyle(Color.aiText2)
                            Spacer()
                            Text(series.name).foregroundStyle(Color.aiText1)
                        }
                        HStack {
                            Text("描述").foregroundStyle(Color.aiText2)
                            Spacer()
                            Text(series.description.isEmpty ? "—" : series.description)
                                .foregroundStyle(Color.aiText1)
                                .lineLimit(3)
                        }
                    }
                    
                    Section("分集 (\(episodes.count))") {
                        if episodes.isEmpty {
                            Text("暂无分集，点击 + 创建")
                                .foregroundStyle(Color.aiText2)
                        } else {
                            ForEach(episodes) { ep in
                                NavigationLink(value: ep.id) {
                                    EpisodeRow(project: ep)
                                }
                            }
                            .onDelete(perform: deleteEpisode)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(series.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingCreate = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .navigationDestination(for: UUID.self) { projectId in
                    ProjectDetailView(projectId: projectId)
                }
                .sheet(isPresented: $showingCreate) {
                    CreateEpisodeView(seriesId: seriesId)
                }
                .onAppear { loadSeries() }
                .alert("错误", isPresented: $showError) {
                    Button("确定") {}
                } message: {
                    Text(projectStore.lastError ?? "")
                }
            } else {
                ProgressView().task { await loadSeries() }
            }
        }
    }
    
    private func loadSeries() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let detail = try await APIClient.shared.fetchSeries(id: seriesId)
            series = Series(
                id: detail.id,
                name: detail.name,
                description: detail.description,
                episodesCount: detail.episodes.count,
                createdAt: detail.createdAt
            )
            episodes = detail.episodes
        } catch {
            projectStore.lastError = error.localizedDescription
            showError = true
        }
    }
    
    private func deleteEpisode(at offsets: IndexSet) {
        // 项目在详情页删除由用户手动操作
    }
}

struct EpisodeRow: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: project.isCompleted ? "checkmark.circle.fill" : "film")
                .font(.title3)
                .foregroundStyle(project.isCompleted ? Color.aiSuccess : project.isProcessing ? Color.aiWarning : Color.aiText2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.displayName.isEmpty ? project.name : project.displayName)
                    .foregroundStyle(Color.aiText1)
                HStack {
                    Text(project.statusDisplay)
                        .font(.caption)
                        .foregroundStyle(projectStatusColor)
                    Spacer()
                    if let ep = project.episodeTitle, !ep.isEmpty {
                        Text(ep)
                            .font(.caption)
                            .foregroundStyle(Color.aiText2)
                    }
                }
                if project.progressPercentage > 0 {
                    GeometryReader { g in
                        Rectangle().fill(Color.aiBorder).frame(height: 2)
                        Rectangle()
                            .fill(LinearGradient(colors: [Color.aiPrimary, Color.aiSuccess], startPoint: .leading, endPoint: .trailing))
                            .frame(width: g.size.width * CGFloat(project.progressPercentage) / 100, height: 2)
                    }
                    .cornerRadius(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var projectStatusColor: Color {
        switch project.status {
        case "completed": return Color.aiSuccess
        case "processing", "queued": return Color.aiWarning
        case "failed": return Color.aiError
        default: return Color.aiText2
        }
    }
}

struct CreateEpisodeView: View {
    let seriesId: UUID
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var projectStore: ProjectStore
    @State private var name = ""
    @State private var topic = ""
    @State private var episodeTitle = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("分集名称", text: $name)
                    TextField("原始主题", text: $topic, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("可选信息") {
                    TextField("分集标题", text: $episodeTitle)
                }
            }
            .navigationTitle("新建分集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task { await handleCreate() }
                    }
                    .disabled(name.isEmpty || topic.isEmpty)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定") {}
            } message: {
                Text(projectStore.lastError ?? "")
            }
        }
    }
    
    private func handleCreate() async {
        do {
            let p = try await projectStore.createProject(
                name: name,
                topic: topic,
                seriesId: seriesId,
                episodeTitle: episodeTitle
            )
            dismiss()
        } catch {
            projectStore.lastError = error.localizedDescription
            showError = true
        }
    }
}
