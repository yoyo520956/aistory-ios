import SwiftUI

struct StageView: View {
    let stage: ProjectStage
    @EnvironmentObject var appState: AppState
    @State private var isExecuting = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 状态头
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stage.stageTypeDisplay)
                            .font(.title2).fontWeight(.semibold)
                        Text(stage.stageType)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    StageStatusBadge(status: stage.statusDisplay)
                }
                .padding()
                .background(Color.aiSurface)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 执行按钮
                Button {
                    Task { await runStage() }
                } label: {
                    HStack {
                        if isExecuting { ProgressView() } else { Image(systemName: "play.fill") }
                        Text(isExecuting ? "执行中…" : "执行阶段")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isExecuting ? Color.aiBorder : Color.aiPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isExecuting)
                .padding(.horizontal)
                
                // 输入数据
                if let input = stage.inputData, !input.isEmpty {
                    DataView(title: "输入数据", icon: "doc.plaintext", content: input)
                        .padding(.horizontal)
                }
                
                // 输出数据
                if let output = stage.outputData, !output.isEmpty {
                    DataView(title: "输出结果", icon: "square.on.square", content: output)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                }
                
                if stage.inputData == nil && stage.outputData == nil {
                    Text("暂无数据，执行阶段后数据将显示在此处")
                        .font(.caption).foregroundStyle(.secondary)
                        .padding()
                }
                
                Spacer(minLength: 32)
            }
        }
        .background(Color.aiBg)
        .alert("执行失败", isPresented: .constant(errorMessage != nil)) {
            Button("重试") { Task { await runStage() } }
            Button("取消", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }
    
    private func runStage() async {
        guard let id = appState.selectedProject?.id else { return }
        isExecuting = true; errorMessage = nil
        defer { isExecuting = false }
        do {
            _ = try await APIClient.shared.executeStage(projectId: id, stageName: stage.stageType)
            await appState.refreshProject(id)
        } catch { errorMessage = error.localizedDescription }
    }
}

struct StageStatusBadge: View {
    let status: String
    var color: Color {
        switch status.lowercased() {
        case "completed", "成功": return .aiSuccess
        case "processing", "running": return .aiWarning
        case "failed", "失败": return .aiError
        default: return .secondary
        }
    }
    var body: some View {
        Text(status)
            .font(.caption).fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}

struct DataView: View {
    let title: String
    let icon: String
    let content: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(Color.aiPrimary)
                Text(title).font(.headline)
            }
            ScrollView {
                Text(content)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.primary).textSelection(.enabled)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.aiSurface).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }
}
