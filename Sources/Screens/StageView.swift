import SwiftUI
import AVKit

// MARK: - Stage View

struct StageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var stageData: ProjectStage?
    @State private var storyboards: [StoryboardItem] = []
    @State private var images: [GeneratedImage] = []
    @State private var videos: [GeneratedVideo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isExecuting = false
    
    let stageType: String
    let projectId: UUID
    
    var stageDef: StageDefinition? {
        allStages.first { $0.type == stageType }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    // Stage header
                    if let def = stageDef {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: def.icon)
                                    .font(.title2)
                                    .foregroundStyle(Color.aiPrimary)
                                Text(def.display)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if let data = stageData {
                                    StageBadge(status: data.statusDisplay)
                                }
                            }
                            Text(def.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                    
                    // Execute button
                    if let data = stageData, data.status != "completed" && data.status != "done" {
                        Button {
                            Task { await executeStage() }
                        } label: {
                            HStack {
                                if isExecuting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text(isExecuting ? "运行中…" : "执行 \(stageDef?.display ?? "阶段")")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isExecuting ? Color.aiWarning.opacity(0.3) : Color.aiPrimary)
                            .cornerRadius(8)
                        }
                        .disabled(isExecuting)
                        .padding(.horizontal, 16)
                    }
                    
                    // Content based on stage type
                    StageContent(
                        stageType: stageType,
                        stageData: stageData,
                        storyboards: storyboards,
                        images: images,
                        videos: videos
                    )
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color.aiBg)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") { dismiss() }
                }
            }
            .task {
                await loadStage()
            }
            .overlay {
                if isLoading && stageData == nil {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.aiPrimary))
                }
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func loadStage() async {
        isLoading = true
        defer { isLoading = false }
        do {
            stageData = try await APIClient.shared.fetchStage(projectId: projectId, stageName: stageType)
            switch stageType {
            case "storyboard":
                storyboards = try await APIClient.shared.fetchStoryboards(projectId: projectId)
            case "image_generation":
                images = try await APIClient.shared.fetchImages(projectId: projectId)
            case "video_generation":
                videos = try await APIClient.shared.fetchVideos(projectId: projectId)
            default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func executeStage() async {
        isExecuting = true
        errorMessage = nil
        defer { isExecuting = false }
        do {
            _ = try await APIClient.shared.executeStage(projectId: projectId, stageName: stageType)
            await loadStage()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Stage Content

struct StageContent: View {
    let stageType: String
    let stageData: ProjectStage?
    let storyboards: [StoryboardItem]
    let images: [GeneratedImage]
    let videos: [GeneratedVideo]
    
    var body: some View {
        VStack(spacing: 12) {
            switch stageType {
            case "rewrite":
                RewriteContent(stageData: stageData)
            case "storyboard":
                StoryboardContent(items: storyboards)
            case "image_generation":
                ImageGridContent(images: images)
            case "video_generation":
                VideoListContent(videos: videos)
            default:
                Text("暂无数据")
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Rewrite Content

struct RewriteContent: View {
    let stageData: ProjectStage?
    
    var body: some View {
        VStack(spacing: 12) {
            // Original text
            if let input = stageData?.inputData, !input.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("原文")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.aiPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.aiPrimary.opacity(0.15))
                            .cornerRadius(4)
                        Spacer()
                    }
                    ScrollView(.horizontal) {
                        Text(input)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxHeight: 120)
                }
            }
            
            // Arrow divider
            Image(systemName: "arrow.down")
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            // Rewritten text
            if let output = stageData?.outputData, !output.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("改写文")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.aiSuccess)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.aiSuccess.opacity(0.15))
                            .cornerRadius(4)
                        Spacer()
                    }
                    ScrollView(.horizontal) {
                        Text(output)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxHeight: 200)
                }
            } else {
                Text("改写内容尚未生成")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding()
            }
        }
    }
}

// MARK: - Storyboard Content

struct StoryboardContent: View {
    let items: [StoryboardItem]
    
    var body: some View {
        if items.isEmpty {
            Text("尚未生成分镜")
                .foregroundStyle(.tertiary)
                .padding()
        } else {
            VStack(spacing: 12) {
                ForEach(items.sorted(by: { $0.sequenceNumber < $1.sequenceNumber })) { item in
                    StoryboardCard(item: item)
                }
            }
        }
    }
}

struct StoryboardCard: View {
    let item: StoryboardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sequence number badge
            HStack {
                Text("第 \(item.sequenceNumber) 镜")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.aiPrimary)
                    .cornerRadius(4)
                Spacer()
                Text("\(item.durationSeconds)s")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Scene description
            VStack(alignment: .leading, spacing: 4) {
                Text("画面")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Text(item.sceneDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
            }
            
            // Narration
            VStack(alignment: .leading, spacing: 4) {
                Text("旁白")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Text(item.narrationText)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
            }
            
            // Image prompt (collapsible)
            if !item.imagePrompt.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("图片提示词")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(item.imagePrompt)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineSpacing(2)
                }
                .padding(8)
                .background(Color.aiSurface)
                .cornerRadius(8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.aiBorder, lineWidth: 1)
        )
    }
}

// MARK: - Image Grid Content

struct ImageGridContent: View {
    let images: [GeneratedImage]
    
    var body: some View {
        if images.isEmpty {
            Text("尚未生成图片")
                .foregroundStyle(.tertiary)
                .padding()
        } else {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(images) { img in
                    AsyncImage(url: APIClient.shared.storageImageURL(path: img.imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 140)
                                .cornerRadius(8)
                        case .failure:
                            Rectangle()
                                .fill(Color.aiBorder)
                                .frame(height: 140)
                                .cornerRadius(8)
                                .overlay(
                                    Image(systemName: "photo.fill")
                                        .font(.title2)
                                        .foregroundStyle(.tertiary)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.aiBorder)
                                .frame(height: 140)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Video List Content

struct VideoListContent: View {
    let videos: [GeneratedVideo]
    
    var body: some View {
        if videos.isEmpty {
            Text("尚未生成视频")
                .foregroundStyle(.tertiary)
                .padding()
        } else {
            VStack(spacing: 12) {
                ForEach(videos) { video in
                    VStack(spacing: 8) {
                        VideoPlayer(
                            player: AVPlayer(
                                url: APIClient.shared.storageVideoURL(path: video.videoUrl)
                                    ?? URL(string: "https://www.apple.com")!
                            )
                        )
                        .frame(height: 200)
                        .cornerRadius(8)
                        
                        HStack {
                            Text(formatDuration(video.duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if video.width > 0 && video.height > 0 {
                                Text("\(video.width)×\(video.height)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.aiSurface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.aiBorder, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
