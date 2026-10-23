import SwiftUI

// MARK: - 资产库列表

struct AssetListView: View {
    @State private var assets: [GlobalVariable] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingForm = false
    @State private var editing: GlobalVariable?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty && !isLoading {
                    EmptyState(icon: "person.crop.rectangle.stack",
                               title: "暂无资产",
                               subtitle: "资产 = 角色 / 场景 / 道具，供提示词引用",
                               actionTitle: "新建资产",
                               onAction: { showingForm = true })
                } else {
                    List {
                        ForEach(groupedKeys, id: \.self) { group in
                            Section(group.isEmpty ? "未分组" : group) {
                                ForEach(filtered.filter { $0.group == group }) { asset in
                                    Button {
                                        editing = asset
                                        showingForm = true
                                    } label: {
                                        AssetRow(asset: asset)
                                    }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            Task { await delete(asset) }
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "搜索资产")
                }
            }
            .navigationTitle("资产库")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingForm = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingForm, onDismiss: { Task { await load() } }) {
                AssetFormView(asset: editing)
            }
            .task { await load() }
            .refreshable { await load() }
            .alert("提示", isPresented: .constant(errorMessage != nil)) {
                Button("知道了") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var filtered: [GlobalVariable] {
        guard !searchText.isEmpty else { return assets }
        return assets.filter {
            $0.key.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedKeys: [String] {
        Array(Set(filtered.map { $0.group })).sorted()
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            assets = try await APIClient.shared.fetchAssets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ asset: GlobalVariable) async {
        do {
            try await APIClient.shared.deleteAsset(id: asset.id)
            assets.removeAll { $0.id == asset.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AssetRow: View {
    let asset: GlobalVariable

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.aiPrimary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(asset.key)
                    .foregroundStyle(Color.aiText1)
                if !asset.description.isEmpty {
                    Text(asset.description)
                        .font(.caption)
                        .foregroundStyle(Color.aiText2)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(asset.scopeDisplay.isEmpty ? asset.scope : asset.scopeDisplay)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.aiBorder)
                .foregroundStyle(Color.aiText2)
                .cornerRadius(4)
        }
    }

    private var icon: String {
        switch asset.variableType {
        case "image": return "photo"
        case "text": return "text.alignleft"
        case "json": return "curlybraces"
        default: return "cube"
        }
    }
}

// MARK: - 资产表单

struct AssetFormView: View {
    var asset: GlobalVariable?

    @Environment(\.dismiss) private var dismiss
    @State private var key = ""
    @State private var group = "角色"
    @State private var description = ""
    @State private var variableType = "text"
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let groups = ["角色", "场景", "道具", "风格", "其他"]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("资产名称（key）", text: $key)
                    Picker("分组", selection: $group) {
                        ForEach(groups, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("类型", selection: $variableType) {
                        Text("文本").tag("text")
                        Text("图片").tag("image")
                        Text("JSON").tag("json")
                    }
                }

                Section("描述") {
                    TextField("外形 / 设定描述", text: $description, axis: .vertical)
                        .lineLimit(3...8)
                }

                if asset != nil {
                    Section {
                        Text("修改将同步到服务端")
                            .font(.caption)
                            .foregroundStyle(Color.aiText2)
                    }
                }
            }
            .navigationTitle(asset == nil ? "新建资产" : "编辑资产")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "保存中…" : "保存") {
                        Task { await save() }
                    }
                    .disabled(key.isEmpty || isSaving)
                }
            }
            .onAppear {
                if let a = asset {
                    key = a.key
                    group = a.group.isEmpty ? "其他" : a.group
                    description = a.description
                    variableType = a.variableType.isEmpty ? "text" : a.variableType
                }
            }
            .alert("提示", isPresented: .constant(errorMessage != nil)) {
                Button("知道了") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            if let a = asset {
                _ = try await APIClient.shared.updateAsset(id: a.id, key: key,
                                                           group: group, description: description)
            } else {
                _ = try await APIClient.shared.createAsset(key: key, group: group,
                                                           description: description,
                                                           variableType: variableType)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
