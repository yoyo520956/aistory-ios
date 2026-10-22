import SwiftUI

// MARK: - New Project Screen

struct NewProjectScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var name = ""
    @State private var topic = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(spacing: 20) {
                    // Icon
                    Image(systemName: "film.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.aiPrimary)
                        .padding(.top, 20)
                    
                    // Name field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("项目名称")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        TextField("请输入项目名称", text: $name)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(12)
                            .background(Color.aiSurface)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.aiBorder, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Topic field
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("原始主题 / 小说片段")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("可选")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        TextEditor(text: $topic)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxHeight: 300)
                            .padding(8)
                            .background(Color.aiSurface)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.aiBorder, lineWidth: 1)
                            )
                        Text("支持输入小说原文或故事主题描述")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .background(Color.aiBg)
            .navigationTitle("新建项目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task { await createProject() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    .foregroundStyle(isCreating ? .tertiary : Color.aiPrimary)
                }
            }
            .overlay {
                if isCreating {
                    ZStack {
                        Color.aiBg.opacity(0.6).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.aiPrimary))
                            Text("正在创建项目…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
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
    
    private func createProject() async {
        isCreating = true
        errorMessage = nil
        await appState.createProject(name: name.trimmingCharacters(in: .whitespaces), topic: topic)
        isCreating = false
        if appState.lastError != nil {
            errorMessage = appState.lastError
        } else {
            dismiss()
        }
    }
}
