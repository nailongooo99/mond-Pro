import SwiftUI
import UniformTypeIdentifiers
import PartyUI

private struct SharePayload: Identifiable {
    let id = UUID()
    let url: URL
}

struct BackupLibraryView: View {
    @Binding var dictionary: NSMutableDictionary
    @Binding var isBusy: Bool
    @State private var backups: [MondGestaltBackup] = []
    @State private var showingImporter = false
    @State private var sharePayload: SharePayload?
    @State private var errorMessage: String?
    @State private var restoreCandidate: MondGestaltBackup?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { createBackup() } label: { Label("备份当前 MobileGestalt", systemImage: "plus.circle") }
                    Button { showingImporter = true } label: { Label("导入 plist 备份", systemImage: "square.and.arrow.down") }
                } footer: {
                    Text("备份文件保存在 Documents/MobileGestalt Backups。每次写入前都会自动备份当前文件。")
                }
                if backups.isEmpty {
                    ContentUnavailableView("暂无备份", systemImage: "archivebox")
                } else {
                    Section("本地备份") {
                        ForEach(backups) { backup in
                            HStack(spacing: 12) {
                                Image(systemName: "doc.zipper").foregroundStyle(.tint)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(backup.name).lineLimit(1)
                                    Text("\(backup.createdAt.formatted(date: .abbreviated, time: .shortened)) · \(ByteCountFormatter.string(fromByteCount: backup.byteCount, countStyle: .file))")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Menu {
                                    Button { export(backup) } label: { Label("导出", systemImage: "square.and.arrow.up") }
                                    Button { restoreCandidate = backup } label: { Label("恢复", systemImage: "arrow.uturn.backward") }
                                    Button(role: .destructive) { delete(backup) } label: { Label("删除", systemImage: "trash") }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("备份恢复")
            .onAppear { refresh() }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.propertyList, .data], allowsMultipleSelection: false) { result in
                if case .success(let urls) = result, let url = urls.first { importBackup(url) }
            }
            .sheet(item: $sharePayload) { payload in ActivityView(activityItems: [payload.url]) }
            .confirmationDialog("恢复 MobileGestalt？", isPresented: Binding(get: { restoreCandidate != nil }, set: { if !$0 { restoreCandidate = nil } }), titleVisibility: .visible) {
                Button("恢复并写入", role: .destructive) { if let backup = restoreCandidate { restore(backup) }; restoreCandidate = nil }
                Button("取消", role: .cancel) { restoreCandidate = nil }
            } message: { Text("当前 MobileGestalt 会先自动备份。恢复后请重启设备。") }
            .alert("操作失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("确定") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private func refresh() { backups = (try? MondGestaltBackupStore.list()) ?? [] }
    private func createBackup() {
        do { _ = try MondGestaltBackupStore.create(from: Data(contentsOf: URL(fileURLWithPath: TweakPaths.gestalt))); refresh() }
        catch { errorMessage = error.localizedDescription }
    }
    private func importBackup(_ url: URL) {
        let accessed = url.startAccessingSecurityScopedResource(); defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            var format = PropertyListSerialization.PropertyListFormat.binary
            guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: &format) as? [String: Any], plist["CacheExtra"] != nil else { throw NSError(domain: "mond", code: 1, userInfo: [NSLocalizedDescriptionKey: "所选文件不是有效的 MobileGestalt plist。"]) }
            _ = try MondGestaltBackupStore.create(from: data); refresh()
        } catch { errorMessage = error.localizedDescription }
    }
    private func export(_ backup: MondGestaltBackup) {
        do {
            let destination = FileManager.default.temporaryDirectory.appendingPathComponent(backup.url.lastPathComponent)
            try? FileManager.default.removeItem(at: destination)
            try MondGestaltBackupStore.data(for: backup).write(to: destination, options: .atomic)
            sharePayload = SharePayload(url: destination)
        } catch { errorMessage = error.localizedDescription }
    }
    private func restore(_ backup: MondGestaltBackup) {
        do {
            _ = try MondGestaltBackupStore.create(from: Data(contentsOf: URL(fileURLWithPath: TweakPaths.gestalt)))
            try writeGestaltData(MondGestaltBackupStore.data(for: backup))
            dictionary = try NSMutableDictionary(contentsOf: URL(fileURLWithPath: TweakPaths.gestalt), error: ())
            refresh()
        } catch { errorMessage = error.localizedDescription }
    }
    private func delete(_ backup: MondGestaltBackup) { do { try MondGestaltBackupStore.delete(backup); refresh() } catch { errorMessage = error.localizedDescription } }
}

#if canImport(UIKit)
private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: activityItems, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#endif
