import SwiftUI
import UIKit
import PartyUI

struct AdvancedGestaltEditorView: View {
    @EnvironmentObject var state: AppState
    @Binding var dictionary: NSMutableDictionary
    @Binding var isBusy: Bool
    @State private var search = ""
    @State private var editingKey: EditableKey?
    @State private var showingAdd = false
    @State private var errorMessage: String?

    private struct EditableKey: Identifiable {
        let id = UUID()
        let key: String
        let isCacheExtra: Bool
    }

    private var model: EditableGestaltPlist {
        EditableGestaltPlist(dict: normalizedPlistValue(dictionary) as? [String: Any] ?? [:])
    }

    private var filteredTop: [String] { model.topLevelKeys.filter(matches) }
    private var filteredCache: [String] { model.cacheExtraKeys.filter(matches) }

    var body: some View {
        NavigationStack {
            List {
                if model.dict.isEmpty {
                    ContentUnavailableView("未读取 MobileGestalt", systemImage: "doc.text.magnifyingglass", description: Text("请先在工具页加载文件。"))
                } else {
                    Section("顶层字段（\(filteredTop.count)）") {
                        ForEach(filteredTop, id: \.self) { key in
                            keyRow(key, cache: false)
                        }
                    }
                    Section {
                        ForEach(filteredCache, id: \.self) { key in
                            keyRow(key, cache: true)
                        }
                        Button { showingAdd = true } label: {
                            Label("新增 CacheExtra 字段", systemImage: "plus")
                        }
                    } header: {
                        Text("CacheExtra（\(filteredCache.count)）")
                    }
                }
            }
            .searchable(text: $search, prompt: "搜索字段名或字段值")
            .navigationTitle("高级字段")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }.disabled(isBusy || model.dict.isEmpty)
                }
            }
            .sheet(item: $editingKey) { item in
                ValueEditorView(
                    title: item.key,
                    value: item.isCacheExtra ? model.cacheValue(forKey: item.key) : model.value(forKey: item.key),
                    allowsDelete: item.isCacheExtra,
                    onSave: { value in
                        update(value: value, key: item.key, cache: item.isCacheExtra)
                    },
                    onDelete: item.isCacheExtra ? { deleteCache(item.key) } : nil
                )
            }
            .sheet(isPresented: $showingAdd) {
                AddCacheExtraFieldView { key, value in
                    var updated = model
                    updated.setCacheValue(value, forKey: key)
                    dictionary = NSMutableDictionary(dictionary: updated.dict)
                }
            }
            .alert("操作失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("确定") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    @ViewBuilder private func keyRow(_ key: String, cache: Bool) -> some View {
        let value = cache ? model.cacheValue(forKey: key) : model.value(forKey: key)
        let info = EditablePlistValueInfo.info(for: value)
        Button { editingKey = EditableKey(key: key, isCacheExtra: cache) } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(key).font(.body).textSelection(.enabled)
                Text("\(info.kind.title) · \(info.summary)").font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .foregroundStyle(.primary)
        .contextMenu { if cache { Button("删除字段", role: .destructive) { deleteCache(key) } } }
    }

    private func matches(_ key: String) -> Bool {
        guard !search.isEmpty else { return true }
        let value = model.value(forKey: key) ?? model.cacheValue(forKey: key)
        return key.localizedCaseInsensitiveContains(search) || EditablePlistValueInfo.info(for: value).encoded.localizedCaseInsensitiveContains(search)
    }

    private func update(value: Any, key: String, cache: Bool) {
        var updated = model
        if cache { updated.setCacheValue(value, forKey: key) } else { updated.setValue(value, forKey: key) }
        dictionary = NSMutableDictionary(dictionary: updated.dict)
    }

    private func deleteCache(_ key: String) {
        var updated = model
        updated.removeCacheValue(forKey: key)
        dictionary = NSMutableDictionary(dictionary: updated.dict)
    }

    private func save() {
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .binary, options: 0)
            let original = try Data(contentsOf: URL(fileURLWithPath: TweakPaths.gestalt))
            _ = try MondGestaltBackupStore.create(from: original)
            try writeGestaltData(data)
            isBusy = false
            Alertinator.shared.alert(title: "已保存字段", body: "MobileGestalt 已写入并自动备份。请重启设备使更改生效。")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ValueEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let value: Any?
    let allowsDelete: Bool
    let onSave: (Any) -> Void
    let onDelete: (() -> Void)?
    @State private var kind: EditablePlistValueKind
    @State private var text: String
    @State private var error: String?

    init(title: String, value: Any?, allowsDelete: Bool, onSave: @escaping (Any) -> Void, onDelete: (() -> Void)?) {
        self.title = title; self.value = value; self.allowsDelete = allowsDelete; self.onSave = onSave; self.onDelete = onDelete
        let info = EditablePlistValueInfo.info(for: value)
        _kind = State(initialValue: info.kind); _text = State(initialValue: info.encoded)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("类型") {
                    Picker("字段类型", selection: $kind) { ForEach(EditablePlistValueKind.allCases) { Text($0.title).tag($0) } }
                }
                Section("值") {
                    if kind == .boolean {
                        Toggle("启用", isOn: Binding(get: { text.lowercased() == "true" }, set: { text = $0 ? "true" : "false" }))
                    } else {
                        TextEditor(text: $text).frame(minHeight: kind == .array || kind == .dictionary ? 220 : 100).font(.system(.body, design: .monospaced))
                    }
                }
                if let error { Text(error).foregroundStyle(.red) }
                if allowsDelete, let onDelete { Section { Button("删除此字段", role: .destructive) { onDelete(); dismiss() } } }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { save() } }
            }
        }
    }

    private func save() {
        do { onSave(try EditablePlistValueInfo.parse(text, as: kind)); dismiss() }
        catch let caughtError { self.error = caughtError.localizedDescription }
    }
}

private struct AddCacheExtraFieldView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, Any) -> Void
    @State private var key = ""
    @State private var kind: EditablePlistValueKind = .string
    @State private var text = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("字段名", text: $key)
                Picker("类型", selection: $kind) { ForEach(EditablePlistValueKind.allCases) { Text($0.title).tag($0) } }
                TextEditor(text: $text).frame(minHeight: 120).font(.system(.body, design: .monospaced))
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("新增字段")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("添加") { add() }.disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
        }
    }

    private func add() {
        do { onAdd(key.trimmingCharacters(in: .whitespacesAndNewlines), try EditablePlistValueInfo.parse(text, as: kind)); dismiss() }
        catch let caughtError { error = caughtError.localizedDescription }
    }
}
