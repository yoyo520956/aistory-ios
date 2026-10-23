import SwiftUI
import AVKit

// MARK: - 阶段产出展示

struct StageOutputSection: View {
    let stages: [ProjectStage]
    let project: Project

    var body: some View {
        VStack(spacing: 16) {
            ForEach(StageType.allCases, id: \.self) { type in
                if let stage = stages.first(where: { $0.stageType == type.rawValue }),
                   let out = stage.outputData {
                    outputBlock(for: type, stage: stage, out: out)
                }
            }
        }
    }

    @ViewBuilder
    private func outputBlock(for type: StageType, stage: ProjectStage, out: JSONValue) -> some View {
        switch type {
        case .rewrite, .assetExtraction:
            TextOutputCard(title: stage.stageTypeDisplay.isEmpty ? type.displayName : stage.stageTypeDisplay,
                           text: extractText(out))
        case .storyboard:
            StoryboardCard(stage: stage, out: out)
        case .imageGeneration, .multiGridImage, .imageEdit:
            MediaGridCard(title: type.displayName, items: extractMediaURLs(out))
        case .cameraMovement:
            TextOutputCard(title: type.displayName, text: extractText(out))
        case .videoGeneration:
            VideoListCard(title: type.displayName, items: extractMediaURLs(out))
        }
    }

    // MARK: - Extractors

    private func extractText(_ out: JSONValue) -> String {
        guard let obj = out.objectValue else { return out.stringValue ?? "" }
        for key in ["raw_text", "source_text", "text", "content", "summary"] {
            if let v = obj[key], let s = v.stringValue, !s.isEmpty {
                return s
            }
        }
        // 退化为遍历所有长字符串
        for (_, v) in obj {
            if let s = v.stringValue, s.count > 40 { return s }
        }
        return ""
    }

    private func extractMediaURLs(_ out: JSONValue) -> [String] {
        var result: [String] = []
        let obj = out.objectValue

        func scan(_ v: JSONValue) {
            switch v {
            case .object(let o):
                for (k, sub) in o {
                    if k.contains("url") || k.contains("path") || k == "image" || k == "video" {
                        if let s = sub.stringValue, !s.isEmpty { result.append(s) }
                    }
                    scan(sub)
                }
            case .array(let arr):
                for item in arr { scan(item) }
            case .string(let s):
                if s.hasPrefix("http") { result.append(s) }
            default:
                break
            }
        }

        if let obj {
            for (_, v) in obj { scan(v) }
        } else {
            scan(out)
        }
        return Array(Set(result)).sorted()
    }
}

// MARK: - 文本卡片

struct TextOutputCard: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline).foregroundStyle(Color.aiText1)
                Spacer()
                Text("\(text.count) 字").font(.caption2).foregroundStyle(Color.aiText2)
            }
            Divider().background(Color.aiBorder)
            if text.isEmpty {
                Text("暂无内容").font(.subheadline).foregroundStyle(Color.aiText2)
            } else {
                Text(text)
                    .font(.callout)
                    .foregroundStyle(Color.aiText1)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }
}

// MARK: - 分镜卡片

struct StoryboardCard: View {
    let stage: ProjectStage
    let out: JSONValue

    private var items: [JSONValue] {
        if let arr = out.objectValue?["items"]?.arrayValue { return arr }
        if let arr = out.arrayValue { return arr }
        return []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stage.stageTypeDisplay.isEmpty ? "分镜生成" : stage.stageTypeDisplay)
                    .font(.headline).foregroundStyle(Color.aiText1)
                Spacer()
                Text("\(items.count) 个镜头").font(.caption2).foregroundStyle(Color.aiText2)
            }
            Divider().background(Color.aiBorder)
            if items.isEmpty {
                Text("暂无分镜").font(.subheadline).foregroundStyle(Color.aiText2)
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    StoryboardItemCard(index: index + 1, item: item)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }
}

struct StoryboardItemCard: View {
    let index: Int
    let item: JSONValue

    var body: some View {
        let obj = item.objectValue ?? [:]

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("#\(index)")
                    .font(.caption).fontWeight(.bold)
                    .foregroundStyle(Color.aiPrimary)
                Spacer()
                if let dur = obj["duration_seconds"]?.intValue ?? obj["duration"]?.intValue {
                    Text("\(dur) 秒").font(.caption2).foregroundStyle(Color.aiText2)
                }
            }

            if let scene = obj["scene_description"]?.stringValue, !scene.isEmpty {
                Text(scene).font(.subheadline).foregroundStyle(Color.aiText1)
            }
            if let narration = obj["narration_text"]?.stringValue, !narration.isEmpty {
                Text("旁白：\(narration)").font(.caption).foregroundStyle(Color.aiText2)
            }
            if let prompt = obj["image_prompt"]?.stringValue, !prompt.isEmpty {
                Text("画面：\(prompt)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color.aiText2)
            }
            if let url = obj["image_url"]?.stringValue ?? obj["image"]?.stringValue,
               let u = URL(string: url) {
                AsyncImage(url: u) { phase in
                    if let img = phase.image {
                        img.resizable().aspectRatio(contentMode: .fit).cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.aiBorder).frame(height: 120)
                            .overlay(ProgressView())
                    }
                }
            }
        }
        .padding(10)
        .background(Color.aiBg)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.aiBorder, lineWidth: 0.5))
    }
}

// MARK: - 图片网格

struct MediaGridCard: View {
    let title: String
    let items: [String]

    let columns = [GridItem(.adaptive(minimum: 140, maximum: 160), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline).foregroundStyle(Color.aiText1)
                Spacer()
                Text("\(items.count) 张").font(.caption2).foregroundStyle(Color.aiText2)
            }
            if items.isEmpty {
                Text("暂无图片").font(.subheadline).foregroundStyle(Color.aiText2)
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(items, id: \.self) { path in
                        if let url = APIClient.shared.absoluteURL(path) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable()
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipped()
                                        .cornerRadius(8)
                                case .failure:
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.aiBorder)
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay(Image(systemName: "photo").foregroundStyle(Color.aiText2))
                                case .empty:
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.aiSurface)
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay(ProgressView())
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }
}

// MARK: - 视频列表

struct VideoListCard: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline).foregroundStyle(Color.aiText1)
                Spacer()
                Text("\(items.count) 个").font(.caption2).foregroundStyle(Color.aiText2)
            }
            if items.isEmpty {
                Text("暂无视频").font(.subheadline).foregroundStyle(Color.aiText2)
            } else {
                ForEach(items, id: \.self) { path in
                    if let url = APIClient.shared.absoluteURL(path) {
                        VideoPlayerView(url: url)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }
}
