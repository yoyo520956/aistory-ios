import SwiftUI

// MARK: - 提示词调试工作台

struct PromptDebugView: View {
    let template: PromptTemplate

    @EnvironmentObject var modelStore: ModelStore
    @State private var sessionId: String?
    @State private var templateContent = ""
    @State private var variableText = ""          // 每行 key=value
    @State private var inputText = ""             // 每行 key=value
    @State private var selectedProviderId: UUID?
    @State private var isRunning = false
    @State private var outputText = ""
    @State private var errorMessage: String?
    @State private var runStatus = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // 模板信息
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("调试模板").font(.headline).foregroundStyle(Color.aiText1)
                        Spacer()
                        Text(StageType(rawValue: template.stageType)?.displayName ?? template.stageType)
                            .font(.caption)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.aiPrimary.opacity(0.15))
                            .foregroundStyle(Color.aiPrimary)
                            .cornerRadius(4)
                    }
                    Text(template.name)
                        .font(.caption).foregroundStyle(Color.aiText2)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.aiSurface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))

                // 模板内容
                VStack(alignment: .leading, spacing: 6) {
                    Text("模板内容（Jinja2）").font(.caption).foregroundStyle(Color.aiText2)
                    TextEditor(text: $templateContent)
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                        .font(.system(.footnote, design: .monospaced))
                        .padding(8)
                        .background(Color.aiSurface)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.aiBorder, lineWidth: 0.5))
                }

                // 变量
                VStack(alignment: .leading, spacing: 6) {
                    Text("变量值（每行 key=value）").font(.caption).foregroundStyle(Color.aiText2)
                    TextEditor(text: $variableText)
                        .frame(minHeight: 70)
                        .scrollContentBackground(.hidden)
                        .font(.system(.footnote, design: .monospaced))
                        .padding(8)
                        .background(Color.aiSurface)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.aiBorder, lineWidth: 0.5))
                }

                // 输入
                VStack(alignment: .leading, spacing: 6) {
                    Text("输入 payload（每行 key=value）").font(.caption).foregroundStyle(Color.aiText2)
                    TextEditor(text: $inputText)
                        .frame(minHeight: 70)
                        .scrollContentBackground(.hidden)
                        .font(.system(.footnote, design: .monospaced))
                        .padding(8)
                        .background(Color.aiSurface)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.aiBorder, lineWidth: 0.5))
                }

                // 模型
                VStack(alignment: .leading, spacing: 6) {
                    Text("调试模型").font(.caption).foregroundStyle(Color.aiText2)
                    Picker("模型", selection: $selectedProviderId) {
                        Text("默认").tag(nil as UUID?)
                        ForEach(modelStore.providers.filter { $0.providerType == "llm" && $0.isActive }) { p in
                            Text("\(p.name) · \(p.modelName)").tag(p.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 运行按钮
                Button {
                    Task { await run() }
                } label: {
                    HStack {
                        if isRunning { ProgressView().tint(.white) }
                        Image(systemName: "play.fill")
                        Text(isRunning ? "运行中…" : "运行调试")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.aiPrimary)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(isRunning)

                if !runStatus.isEmpty {
                    Text(runStatus).font(.caption).foregroundStyle(Color.aiText2)
                }

                // 输出
                if !outputText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("输出").font(.headline).foregroundStyle(Color.aiText1)
                            Spacer()
                            Text("\(outputText.count) 字").font(.caption2).foregroundStyle(Color.aiText2)
                        }
                        Divider().background(Color.aiBorder)
                        Text(outputText)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(Color.aiText1)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.aiSurface)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(Color.aiBg)
        .navigationTitle("调试工作台")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if templateContent.isEmpty {
                templateContent = template.systemPrompt.isEmpty ? template.userPrompt : template.systemPrompt
            }
            await bootstrap()
        }
        .alert("提示", isPresented: .constant(errorMessage != nil)) {
            Button("知道了") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func parseKV(_ text: String) -> [String: String] {
        var dict: [String: String] = [:]
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                dict[parts[0].trimmingCharacters(in: .whitespaces)] =
                    parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return dict
    }

    private func bootstrap() async {
        do {
            let s = try await APIClient.shared.bootstrapDebug(templateId: template.id)
            sessionId = s.id
            if !s.draftContent.isEmpty { templateContent = s.draftContent }
            runStatus = "会话已就绪"
        } catch {
            runStatus = "会话初始化失败：\(error.localizedDescription)"
        }
    }

    private func run() async {
        guard let sid = sessionId else {
            errorMessage = "调试会话未就绪"
            return
        }
        isRunning = true
        outputText = ""
        runStatus = "运行中…"
        defer { isRunning = false }
        do {
            let result = try await APIClient.shared.runDebug(
                sessionId: sid,
                templateContent: templateContent,
                variables: parseKV(variableText),
                input: parseKV(inputText),
                providerId: selectedProviderId)
            outputText = result.output
            runStatus = "运行完成（\(result.status)）"
        } catch {
            errorMessage = error.localizedDescription
            runStatus = "运行失败"
        }
    }
}
