import Foundation

func writeGestaltData(_ data: Data) throws {
    let targetURL = URL(fileURLWithPath: TweakPaths.gestalt)
    let temporaryURL = targetURL.deletingLastPathComponent()
        .appendingPathComponent(".\(targetURL.lastPathComponent).\(UUID().uuidString).tmp")
    try data.write(to: temporaryURL, options: [.withoutOverwriting])
    defer { try? FileManager.default.removeItem(at: temporaryURL) }
    if FileManager.default.fileExists(atPath: targetURL.path) {
        _ = try FileManager.default.replaceItemAt(targetURL, withItemAt: temporaryURL)
    } else {
        try FileManager.default.moveItem(at: temporaryURL, to: targetURL)
    }
}

struct MondGestaltBackup: Identifiable, Hashable {
    let url: URL
    let createdAt: Date
    let byteCount: Int64
    var id: URL { url }
    var name: String { url.deletingPathExtension().lastPathComponent }
}

enum MondGestaltBackupStore {
    static func create(from data: Data) throws -> MondGestaltBackup {
        let directory = try directory()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
        let url = directory.appendingPathComponent("MobileGestalt_\(formatter.string(from: Date()))").appendingPathExtension("plist")
        try data.write(to: url, options: .atomic)
        return try metadata(for: url)
    }

    static func list() throws -> [MondGestaltBackup] {
        try FileManager.default.contentsOfDirectory(at: directory(), includingPropertiesForKeys: [.creationDateKey, .fileSizeKey], options: [.skipsHiddenFiles])
            .filter { $0.pathExtension.lowercased() == "plist" }
            .compactMap { try? metadata(for: $0) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    static func data(for backup: MondGestaltBackup) throws -> Data { try Data(contentsOf: backup.url) }
    static func delete(_ backup: MondGestaltBackup) throws { try FileManager.default.removeItem(at: backup.url) }

    private static func directory() throws -> URL {
        let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = documents.appendingPathComponent("MobileGestalt Backups", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func metadata(for url: URL) throws -> MondGestaltBackup {
        let values = try url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
        return MondGestaltBackup(url: url, createdAt: values.creationDate ?? .distantPast, byteCount: Int64(values.fileSize ?? 0))
    }
}
