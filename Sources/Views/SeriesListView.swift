import SwiftUI

struct SeriesListView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var authStore: AuthStore
    @State private var showingCreate = false
    @State private var newName = ""
    @State private var newDesc = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if projectStore.series.isEmpty && !projectStore.isLoading {
                    EmptyState(icon: "photo.on.rectangle", title: "暂无作品", subtitle: "创建你的第一个作品")
                        .padding()
                } else {
                    List {
                        ForEach(projectStore.series) { series in
                            NavigationLink(value: series.id) {
                                SeriesRow(series: series)
                            }
                        }
                        .onDelete(perform: deleteSeries)
                    }
                }
            }
            .navigationTitle("作品")
            .navigationDestination(for: UUID.self) { id in
                SeriesDetailView(seriesId: id)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateSeriesView()
            }
            .alert("错误", isPresented: $showError) {
                Button("确定") {}
            } message: {
                Text(projectStore.lastError ?? "")
            }
        }
    }
    
    private func deleteSeries(at offsets: IndexSet) {
        for index in offsets {
            let series = projectStore.series[index]
            Task {
                do {
                    try await projectStore.deleteSeries(series.id)
                } catch {
                    showError = true
                }
            }
        }
    }
}

struct SeriesRow: View {
    let series: Series
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle")
                .font(.title2)
                .foregroundStyle(Color.aiPrimary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(series.name)
                    .font(.body)
                    .foregroundStyle(Color.aiText1)
                Text("\(series.episodesCount) 集")
                    .font(.caption)
                    .foregroundStyle(Color.aiText2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.aiText2)
        }
        .padding(.vertical, 4)
    }
}

struct CreateSeriesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var projectStore: ProjectStore
    @State private var name = ""
    @State private var description = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("作品信息") {
                    TextField("作品名称", text: $name)
                    TextField("作品描述（可选）", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("新建作品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task { await handleCreate() }
                    }
                    .disabled(name.isEmpty)
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
            _ = try await projectStore.createSeries(name: name, description: description)
            dismiss()
        } catch {
            projectStore.lastError = error.localizedDescription
            showError = true
        }
    }
}
