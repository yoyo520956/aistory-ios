import SwiftUI

// MARK: - 剧本列表

struct ScreenplayListView: View {
    @State private var screenplays: [Screenplay] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if screenplays.isEmpty && !isLoading {
                    EmptyState(icon: "doc.text",
                               title: "暂无剧本",
                               subtitle: "在网页端创建剧本，或从后端同步")
                } else {
                    List {
                        ForEach(screenplays) { sp in
                            NavigationLink(value: sp.id) {
                                ScreenplayRow(screenplay: sp)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("剧本")
            .navigationDestination(for: UUID.self) { id in
                ScreenplayDetailView(screenplayId: id)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            screenplays = try await APIClient.shared.fetchScreenplays()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ScreenplayRow: View {
    let screenplay: Screenplay

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.title3)
                .foregroundStyle(Color.aiPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(screenplay.title.isEmpty ? "未命名剧本" : screenplay.title)
                    .foregroundStyle(Color.aiText1)
                HStack(spacing: 8) {
                    Text("\(screenplay.totalEpisodes) 集")
                        .font(.caption)
                        .foregroundStyle(Color.aiText2)
                    if screenplay.completedEpisodes > 0 {
                        Text("已完成 \(screenplay.completedEpisodes)")
                            .font(.caption)
                            .foregroundStyle(Color.aiSuccess)
                    }
                }
                if !screenplay.description.isEmpty {
                    Text(screenplay.description)
                        .font(.caption)
                        .foregroundStyle(Color.aiText2)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.aiText2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 剧本详情（分集列表）

struct ScreenplayDetailView: View {
    let screenplayId: UUID
    @State private var screenplay: Screenplay?
    @State private var episodes: [Episode] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let sp = screenplay {
                List {
                    Section("剧本信息") {
                        LabeledRow(label: "标题", value: sp.title)
                        if !sp.description.isEmpty {
                            LabeledRow(label: "简介", value: sp.description)
                        }
                        LabeledRow(label: "总集数", value: "\(sp.totalEpisodes)")
                        LabeledRow(label: "已完成", value: "\(sp.completedEpisodes)")
                    }

                    Section("分集 (\(episodes.count))") {
                        if episodes.isEmpty {
                            Text("暂无分集")
                                .foregroundStyle(Color.aiText2)
                        } else {
                            ForEach(episodes) { ep in
                                NavigationLink(value: ep.id) {
                                    EpisodeRowView(episode: ep)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(sp.title.isEmpty ? "剧本详情" : sp.title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: UUID.self) { id in
                    EpisodeDetailView(episodeId: id, episodes: episodes)
                }
            } else {
                ProgressView()
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            screenplay = try await APIClient.shared.fetchScreenplay(id: screenplayId)
            episodes = try await APIClient.shared.fetchEpisodes(screenplayId: screenplayId)
        } catch {
            errorMessage = error.localizedDescription
            // 剧本详情失败时仍尝试拉分集
            if let eps = try? await APIClient.shared.fetchEpisodes(screenplayId: screenplayId) {
                episodes = eps
            }
        }
    }
}

struct LabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(Color.aiText2)
                .frame(width: 64, alignment: .leading)
            Spacer()
            Text(value)
                .foregroundStyle(Color.aiText1)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct EpisodeRowView: View {
    let episode: Episode

    var body: some View {
        HStack(spacing: 12) {
            Text("\(episode.number)")
                .font(.caption)
                .fontWeight(.semibold)
                .frame(width: 28, height: 28)
                .background(Color.aiBorder)
                .clipShape(Circle())
                .foregroundStyle(Color.aiText1)

            VStack(alignment: .leading, spacing: 3) {
                Text(episode.title.isEmpty ? "第 \(episode.number) 集" : episode.title)
                    .foregroundStyle(Color.aiText1)
                if !episode.content.isEmpty {
                    Text(episode.content)
                        .font(.caption)
                        .foregroundStyle(Color.aiText2)
                        .lineLimit(2)
                }
            }
            Spacer()
            if episode.projectId != nil {
                Image(systemName: "film")
                    .font(.caption)
                    .foregroundStyle(Color.aiSuccess)
            }
        }
        .padding(.vertical, 2)
    }
}
