import SwiftUI

// MARK: - Home Screen

struct HomeScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var showNewProject = false
    @State private var errorMessage: String?
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            Group {
                if appState.isLoading && appState.projects.isEmpty {
                    ProgressView("加载中…")
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.aiPrimary))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.aiBg)
                } else if appState.projects.isEmpty {
                    EmptyState(
                        icon: "film",
                        title: "还没有故事项目",
                        subtitle: "创建一个新项目，从文本到视频的完整 AI 创作流程",
                        actionTitle: "新建项目",
                        onAction: { showNewProject = true }
                    )
                    .background(Color.aiBg)
                } else {
                    ScrollView(.vertical) {
                        VStack(spacing: 12) {
                            ForEach(appState.projects) { project in
                                ProjectCard(project: project) {
                                    appState.selectedProject = project
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color.aiBg)
                }
            }
            .navigationTitle("AI 故事创作")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showNewProject = true }) {
                        Image(systemName: "plus")
                            .font(.body)
                            .foregroundStyle(Color.aiPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isRefreshing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.aiPrimary))
                    }
                }
            }
            .refreshable {
                isRefreshing = true
                await appState.loadProjects()
                isRefreshing = false
            }
            .onAppear {
                if appState.projects.isEmpty {
                    Task { await appState.loadProjects() }
                }
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task { errorMessage = appState.lastError }
            .sheet(isPresented: $showNewProject) {
                NewProjectScreen()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .background(Color.aiBg)
    }
}
