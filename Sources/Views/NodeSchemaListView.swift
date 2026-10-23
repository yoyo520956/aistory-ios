import SwiftUI

// MARK: - 节点结构定义管理（原版 NodeSchemaManager 的移动端形态）

struct NodeSchemaListView: View {
    @State private var items: [JSONValue] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if items.isEmpty && !isLoading {
                EmptyState(icon: "square.stack.3d.up",
                           title: "暂无节点定义",
                           subtitle: "节点结构定义用于工作流画布")
            } else {
                List {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        NodeSchemaRow(item: item)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("节点结构")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .alert("提示", isPresented: .constant(errorMessage != nil)) {
            Button("知道了") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await APIClient.shared.fetchNodeSchemas()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct NodeSchemaRow: View {
    let item: JSONValue

    var body: some View {
        let obj = item.objectValue ?? [:]
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(obj["name"]?.stringValue ?? obj["node_type"]?.stringValue ?? "节点")
                    .font(.body).foregroundStyle(Color.aiText1)
                Spacer()
                if let t = obj["node_type"]?.stringValue {
                    Text(t)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.aiBorder)
                        .foregroundStyle(Color.aiText2)
                        .cornerRadius(4)
                }
            }
            if let d = obj["description"]?.stringValue, !d.isEmpty {
                Text(d).font(.caption).foregroundStyle(Color.aiText2).lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 剪映草稿导出卡片

struct JianyingDraftCard: View {
    let project: Project
    @State private var statusText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "scissors")
                    .foregroundStyle(Color.aiPrimary)
                Text("剪映草稿").font(.headline).foregroundStyle(Color.aiText1)
                Spacer()
            }

            if let path = project.jianyingDraftPath, !path.isEmpty {
                Text(path)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color.aiText2)
                    .lineLimit(2)

                Button {
                    openJianying()
                } label: {
                    Label("在剪映中打开", systemImage: "arrow.up.forward.app")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.aiPrimary.opacity(0.15))
                        .foregroundStyle(Color.aiPrimary)
                        .cornerRadius(10)
                }
            } else {
                Text("完成视频生成阶段后，后端会生成剪映草稿")
                    .font(.caption)
                    .foregroundStyle(Color.aiText2)
            }

            if let s = statusText {
                Text(s).font(.caption2).foregroundStyle(Color.aiWarning)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }

    private func openJianying() {
        // 剪映的 URL Scheme（剪映专业版 / 移动版）
        if let url = URL(string: "snssdk1112://"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            statusText = "已尝试打开剪映"
        } else if let url = URL(string: "jianyingpro://") {
            UIApplication.shared.open(url)
            statusText = "已尝试打开剪映专业版"
        } else {
            statusText = "未检测到剪映 App，请手动安装"
        }
    }
}
