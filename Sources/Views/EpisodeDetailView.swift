import SwiftUI

// MARK: - 分集详情

struct EpisodeDetailView: View {
    let episodeId: UUID
    /// 从上级页面带过来的分集数组（避免再次请求）
    var episodes: [Episode] = []

    @EnvironmentObject private var projectStore: ProjectStore
    @State private var episode: Episode?
    @State private var showEditor = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let ep = resolvedEpisode {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 头部
                        VStack(alignment: .leading, spacing: 6) {
                            Text(ep.title.isEmpty ? "第 \(ep.number) 集" : ep.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.aiText1)
                            HStack(spacing: 10) {
                                if ep.projectId != nil {
                                    Label("已关联分集项目", systemImage: "link")
                                        .font(.caption)
                                        .foregroundStyle(Color.aiSuccess)
                                } else {
                                    Label("未关联项目", systemImage: "link.badge.plus")
                                        .font(.caption)
                                        .foregroundStyle(Color.aiText2)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.aiSurface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))

                        // 正文
                        VStack(alignment: .leading, spacing: 8) {
                            Text("分集内容")
                                .font(.headline)
                                .foregroundStyle(Color.aiText1)
                            if ep.content.isEmpty {
                                Text("暂无内容")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.aiText2)
                            } else {
                                Text(ep.content)
                                    .font(.body)
                                    .foregroundStyle(Color.aiText1)
                                    .textSelection(.enabled)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.aiSurface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))

                        // 关联项目入口
                        if let pid = ep.projectId {
                            NavigationLink(value: pid) {
                                Label("打开分集项目", systemImage: "film")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.aiPrimary.opacity(0.15))
                                    .foregroundStyle(Color.aiPrimary)
                                    .cornerRadius(12)
                            }
                        } else {
                            Button {
                                Task { await createProjectFromEpisode(ep) }
                            } label: {
                                Label("为此分集创建生成项目", systemImage: "plus.circle")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.aiPrimary)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding()
                }
                .background(Color.aiBg)
                .navigationTitle("分集详情")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: UUID.self) { id in
                    ProjectDetailView(projectId: id)
                }
            } else {
                ProgressView()
            }
        }
        .alert("提示", isPresented: .constant(errorMessage != nil)) {
            Button("知道了") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var resolvedEpisode: Episode? {
        if let episode { return episode }
        return episodes.first { $0.id == episodeId }
    }

    private func createProjectFromEpisode(_ ep: Episode) async {
        do {
            let p = try await projectStore.createProject(
                name: ep.title.isEmpty ? "第 \(ep.number) 集" : ep.title,
                topic: ep.content,
                seriesId: nil,
                episodeTitle: ep.title,
                episodeNumber: ep.number
            )
            errorMessage = "已创建项目「\(p.name)」，可在项目列表中执行阶段"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
