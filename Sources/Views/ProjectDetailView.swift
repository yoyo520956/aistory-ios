import SwiftUI

struct ProjectDetailView: View {
    let projectId: UUID

    @EnvironmentObject var projectStore: ProjectStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var stream = StageStreamStore()

    @State private var project: Project?
    @State private var stages: [ProjectStage] = []
    @State private var showError = false
    @State private var errorText = ""
    @State private var showingEdit = false
    @State private var loading = false
    @State private var showLiveLog = false

    var body: some View {
        Group {
            if let project {
                content(project)
            } else {
                ProgressView("加载中…")
                    .task { await load() }
            }
        }
    }

    @ViewBuilder
    private func content(_ project: Project) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                OverviewCard(project: project)

                ProjectInfoSection(project: project)

                StageExecutionSection(
                    stages: stages,
                    executingStage: stream.activeStage,
                    onExecute: { name in Task { await execute(name) } },
                    onRetry: { name in Task { await retry(name) } }
                )

                if stream.isStreaming || !stream.log.isEmpty || !stream.latestTokens.isEmpty {
                    LiveLogCard(stream: stream, expanded: $showLiveLog)
                }

                StageOutputSection(stages: stages, project: project)

                Spacer(minLength: 24)
            }
            .padding()
        }
        .background(Color.aiBg)
        .navigationTitle(project.displayName.isEmpty ? project.name : project.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("编辑项目", systemImage: "pencil")
                    }
                    Button {
                        Task { await load() }
                    } label: {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                    Button {
                        Task { await runFullPipeline() }
                    } label: {
                        Label("运行完整流程", systemImage: "play.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit, onDismiss: { Task { await load() } }) {
            ProjectEditView(project: project)
        }
        .refreshable { await load() }
        .alert("执行失败", isPresented: $showError) {
            Button("知道了") {}
        } message: {
            Text(errorText)
        }
        .onDisappear { stream.stop() }
    }

    // MARK: - Actions

    private func load() async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            project = try await APIClient.shared.fetchProject(id: projectId)
            stages = (try? await APIClient.shared.fetchStages(projectId: projectId)) ?? []
        } catch {
            errorText = error.localizedDescription
            showError = true
        }
    }

    private func execute(_ stageName: String) async {
        do {
            // 先接流，再触发（避免漏掉早期事件）
            stream.start(projectId: projectId, stage: stageName)
            try await APIClient.shared.executeStage(projectId: projectId, stageName: stageName)
            // 轮询刷新阶段状态
            for _ in 0..<40 {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if let s = try? await APIClient.shared.fetchStages(projectId: projectId) {
                    stages = s
                }
                if stream.finished { break }
            }
            await load()
        } catch {
            errorText = error.localizedDescription
            showError = true
        }
    }

    private func retry(_ stageName: String) async {
        do {
            try await APIClient.shared.retryStage(projectId: projectId, stageName: stageName)
            await load()
        } catch {
            errorText = error.localizedDescription
            showError = true
        }
    }

    private func runFullPipeline() async {
        do {
            stream.start(projectId: projectId, stage: nil)
            try await APIClient.shared.retryPipeline(projectId: projectId)
            for _ in 0..<60 {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if let s = try? await APIClient.shared.fetchStages(projectId: projectId) {
                    stages = s
                }
                if stream.finished { break }
            }
            await load()
        } catch {
            errorText = error.localizedDescription
            showError = true
        }
    }
}
