import SwiftUI

// MARK: - 提示词管理（提示词集 + 模板）

struct PromptListView: View {
    @State private var sets: [PromptTemplateSet] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreate = false
    @State private var newSetName = ""

    var body: some View {
        Group {
            if sets.isEmpty && !isLoading {
                EmptyState(icon: "text.badge.star",
                           title: "暂无提示词集",
                           subtitle: "提示词集决定各阶段调用模型的指令",
                           actionTitle: "新建提示词集",
                           onAction: { showingCreate = true })
            } else {
                List {
                    ForEach(sets) { set in
                        NavigationLink(value: set.id) {
                            PromptSetRow(set: set)
                        }
                        .swipeActions {
                            if !set.isDefault {
                                Button(role: .destructive) {
                                    Task { await delete(set) }
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("提示词")
        .navigationDestination(for: UUID.self) { id in
            PromptSetDetailView(setId: id)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("新建提示词集", isPresented: $showingCreate) {
            TextField("名称", text: $newSetName)
            Button("取消", role: .cancel) { newSetName = "" }
            Button("创建") { Task { await create() } }
        }
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
            sets = try await APIClient.shared.fetchPromptSets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func create() async {
        guard !newSetName.isEmpty else { return }
        do {
            let s = try await APIClient.shared.createPromptSet(name: newSetName)
            sets.insert(s, at: 0)
            newSetName = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ set: PromptTemplateSet) async {
        do {
            try await APIClient.shared.deletePromptSet(id: set.id)
            sets.removeAll { $0.id == set.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PromptSetRow: View {
    let set: PromptTemplateSet

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: set.isDefault ? "star.circle.fill" : "text.badge.star")
                .font(.title3)
                .foregroundStyle(set.isDefault ? Color.aiWarning : Color.aiPrimary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(set.name)
                        .foregroundStyle(Color.aiText1)
                    if set.isDefault {
                        Text("默认")
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.aiWarning.opacity(0.2))
                            .foregroundStyle(Color.aiWarning)
                            .cornerRadius(4)
                    }
                }
                Text("\(set.templates.count) 个模板")
                    .font(.caption)
                    .foregroundStyle(Color.aiText2)
            }
            Spacer()
        }
    }
}

// MARK: - 提示词集详情

struct PromptSetDetailView: View {
    let setId: UUID
    @State private var set: PromptTemplateSet?
    @State private var templates: [PromptTemplate] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("提示词集") {
                LabeledRow(label: "名称", value: set?.name ?? "-")
                LabeledRow(label: "默认", value: (set?.isDefault ?? false) ? "是" : "否")
                LabeledRow(label: "模板数", value: "\(templates.count)")
            }

            Section("阶段模板") {
                if templates.isEmpty {
                    Text("暂无模板")
                        .foregroundStyle(Color.aiText2)
                } else {
                    ForEach(templates) { t in
                        NavigationLink(value: t.id) {
                            PromptTemplateRow(template: t)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(set?.name ?? "提示词集")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: UUID.self) { id in
            PromptTemplateEditorView(templateId: id, templates: templates)
        }
        .task { await load() }
    }

    private func load() async {
        do {
            set = try await APIClient.shared.fetchPromptSet(id: setId)
            templates = try await APIClient.shared.fetchPromptTemplates(setId: setId)
        } catch {
            // 详情失败时退化为按 set 拉模板
            do {
                templates = try await APIClient.shared.fetchPromptTemplates(setId: setId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct PromptTemplateRow: View {
    let template: PromptTemplate

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: stageIcon)
                .font(.title3)
                .foregroundStyle(stageColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(template.name.isEmpty ? stageName : template.name)
                    .foregroundStyle(Color.aiText1)
                Text(stageName)
                    .font(.caption)
                    .foregroundStyle(Color.aiText2)
            }
            Spacer()
            if template.isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.aiText2)
            }
            if !template.isActive {
                Text("停用")
                    .font(.caption2)
                    .foregroundStyle(Color.aiText2)
            }
        }
    }

    private var stageName: String {
        StageType(rawValue: template.stageType)?.displayName ?? template.stageType
    }

    private var stageIcon: String {
        StageType(rawValue: template.stageType)?.iconName ?? "doc.text"
    }

    private var stageColor: Color {
        StageType(rawValue: template.stageType)?.iconColor ?? .secondary
    }
}

// MARK: - 提示词模板编辑器（调试工作台入口）

struct PromptTemplateEditorView: View {
    let templateId: UUID
    var templates: [PromptTemplate] = []

    @Environment(\.dismiss) private var dismiss
    @State private var template: PromptTemplate?
    @State private var name = ""
    @State private var systemPrompt = ""
    @State private var userPrompt = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("模板名称").font(.caption).foregroundStyle(Color.aiText2)
                    TextField("名称", text: $name)
                        .padding(10)
                        .background(Color.aiSurface)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.aiBorder, lineWidth: 0.5))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("System Prompt").font(.caption).foregroundStyle(Color.aiText2)
                        Spacer()
                        Text("\(systemPrompt.count) 字").font(.caption2).foregroundStyle(Color.aiText2)
                    }
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 160)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.aiSurface)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.aiBorder, lineWidth: 0.5))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("User Prompt").font(.caption).foregroundStyle(Color.aiText2)
                        Spacer()
                        Text("\(userPrompt.count) 字").font(.caption2).foregroundStyle(Color.aiText2)
                    }
                    TextEditor(text: $userPrompt)
                        .frame(minHeight: 160)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.aiSurface)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.aiBorder, lineWidth: 0.5))
                }

                if let t = template, t.isLocked {
                    Label("该模板已锁定，通常不应修改", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(Color.aiWarning)
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(Color.aiBg)
        .navigationTitle("编辑模板")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if let t = template {
                    NavigationLink {
                        PromptDebugView(template: t)
                    } label: {
                        Label("调试", systemImage: "antenna.radiowaves.left.and.right")
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "保存中…" : "保存") {
                    Task { await save() }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            if template == nil, let t = templates.first(where: { $0.id == templateId }) {
                apply(t)
            }
        }
        .task { await load() }
        .alert("提示", isPresented: .constant(errorMessage != nil)) {
            Button("知道了") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func apply(_ t: PromptTemplate) {
        template = t
        name = t.name
        systemPrompt = t.systemPrompt
        userPrompt = t.userPrompt
    }

    private func load() async {
        if template != nil { return }
        do {
            let t = try await APIClient.shared.fetchPromptTemplate(id: templateId)
            apply(t)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let updated = try await APIClient.shared.updatePromptTemplate(
                id: templateId, name: name,
                systemPrompt: systemPrompt, userPrompt: userPrompt)
            apply(updated)
            errorMessage = nil
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
