import SwiftUI

struct ProjectCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var projectStore: ProjectStore
    @State private var name = ""
    @State private var topic = ""
    @State private var description = ""
    @State private var selectedSeries: UUID?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("项目名称", text: $name)
                    TextField("原始主题", text: $topic, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("项目描述（可选）", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("所属作品") {
                    if projectStore.series.isEmpty {
                        Text("暂无作品，请先创建")
                            .foregroundStyle(Color.aiText2)
                    } else {
                        Picker("选择作品", selection: $selectedSeries) {
                            Text("不选择").tag(nil as UUID?)
                            ForEach(projectStore.series) { series in
                                Text(series.name).tag(series.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .navigationTitle("新建项目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task { await handleCreate() }
                    }
                    .disabled(name.isEmpty || topic.isEmpty)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定") {}
            } message: {
                Text(projectStore.lastError ?? "")
            }
        }
    }
    
    private func handleCreate() async {
        do {
            _ = try await projectStore.createProject(
                name: name,
                topic: topic,
                seriesId: selectedSeries,
                episodeTitle: nil,
                episodeNumber: nil
            )
            dismiss()
        } catch {
            projectStore.lastError = error.localizedDescription
            showError = true
        }
    }
}

struct ProjectEditView: View {
    let project: Project
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var projectStore: ProjectStore
    @State private var name: String
    @State private var topic: String
    @State private var showError = false
    
    init(project: Project) {
        self.project = project
        self._name = State(initialValue: project.name)
        self._topic = State(initialValue: project.originalTopic)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("编辑项目") {
                    TextField("项目名称", text: $name)
                    TextField("原始主题", text: $topic, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("编辑项目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task { await handleSave() }
                    }
                    .disabled(name.isEmpty || topic.isEmpty)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定") {}
            } message: {
                Text(projectStore.lastError ?? "")
            }
        }
    }
    
    private func handleSave() async {
        do {
            try await projectStore.updateProject(id: project.id, name: name, topic: topic, description: "")
            dismiss()
        } catch {
            projectStore.lastError = error.localizedDescription
            showError = true
        }
    }
}
