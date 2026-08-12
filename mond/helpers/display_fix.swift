//
//  display_fix.swift
//  mond
//
//  Optional Dynamic Island display canvas/status bar correction.
//

import Foundation

struct DisplayCanvasProfile: Identifiable, Equatable {
    let id: Int
    let name: String
    let width: Int
    let height: Int

    static let iphone14Pro = DisplayCanvasProfile(id: 2556, name: "iPhone 14 Pro", width: 1179, height: 2556)
    static let iphone14ProMax = DisplayCanvasProfile(id: 2796, name: "iPhone 14 Pro Max", width: 1290, height: 2796)
    static let iphone16Pro = DisplayCanvasProfile(id: 2622, name: "iPhone 16 Pro", width: 1206, height: 2622)
    static let iphone16ProMax = DisplayCanvasProfile(id: 2868, name: "iPhone 16 Pro Max", width: 1320, height: 2868)
    static let iphoneAir = DisplayCanvasProfile(id: 2736, name: "iPhone Air", width: 1260, height: 2736)

    static let all: [DisplayCanvasProfile] = [
        .iphone14Pro,
        .iphone14ProMax,
        .iphone16Pro,
        .iphone16ProMax,
        .iphoneAir,
    ]

    static func forSubtype(_ subtype: Int) -> DisplayCanvasProfile? {
        all.first { $0.id == subtype }
    }
}

struct CanvasPlistStore {
    private static var accessGranted = false

    @discardableResult
    static func ensureAccess() -> Bool {
        if accessGranted { return true }

        // Request both the file and its parent directory. The sandbox can hide
        // a system path before an extension is consumed, so fileExists() is
        // deliberately never used as a prerequisite here.
        let paths = TweakPaths.canvasPlistCandidates + TweakPaths.canvasPlistCandidates.map {
            URL(fileURLWithPath: $0).deletingLastPathComponent().path
        }
        for path in Array(Set(paths)) {
            if let token = sandbox_extension_issue_file(path: path),
               (sandbox_extension_consume(token) ?? -1) >= 0 {
                accessGranted = true
                return true
            }
        }

        // On builds where the app cannot issue a direct system-file extension,
        // try the known plist directory through the container query helper.
        // This is only an access grant; the actual plist is written atomically.
        for plistPath in TweakPaths.canvasPlistCandidates {
            let fileURL = URL(fileURLWithPath: plistPath)
            var directoryCString = fileURL.deletingLastPathComponent().path.utf8CString.map { Int8($0) }
            let handle = bad_query_file(&directoryCString, false, nil, false, fileURL.lastPathComponent)
            if handle >= 0 {
                accessGranted = true
                return true
            }
        }
        return false
    }

    static var existingURL: URL? {
        _ = ensureAccess()
        return TweakPaths.canvasPlistCandidates
            .map { URL(fileURLWithPath: $0) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }

    static var writableURL: URL? {
        if let existingURL { return existingURL }
        // iOS 27 devices commonly use the managed-preferences path. Return it
        // after access is granted so a missing pre-existing plist can be created.
        guard ensureAccess() else { return nil }
        return TweakPaths.canvasPlistCandidates
            .map { URL(fileURLWithPath: $0) }
            .first { $0.path.contains("Managed Preferences/mobile") }
    }

    static func read() throws -> (URL, NSMutableDictionary) {
        guard let url = existingURL else {
            throw CanvasPlistError.fileNotFound
        }
        do {
            let dict: NSMutableDictionary = try NSMutableDictionary(contentsOf: url, error: ())
            return (url, dict)
        } catch {
            throw CanvasPlistError.invalidPlist
        }
    }

    static func readOrCreate() throws -> (URL, NSMutableDictionary) {
        if let existingURL {
            return try read()
        }
        guard let url = writableURL else {
            throw CanvasPlistError.fileNotFound
        }
        return (url, NSMutableDictionary())
    }

    static func write(_ dict: NSMutableDictionary, to url: URL) throws {
        let parent = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parent.path) {
            throw CanvasPlistError.directoryNotFound
        }
        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        let tempURL = url.deletingLastPathComponent()
            .appendingPathComponent(".\(url.lastPathComponent).\(UUID().uuidString).tmp")
        try data.write(to: tempURL, options: [.withoutOverwriting])
        defer { try? FileManager.default.removeItem(at: tempURL) }

        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tempURL)
        } else {
            try FileManager.default.moveItem(at: tempURL, to: url)
        }
    }

    static func backupURL() -> URL {
        URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedCanvas.plist")
    }

    static func ensureBackup(for url: URL) throws {
        let backup = backupURL()
        if !FileManager.default.fileExists(atPath: backup.path) {
            try FileManager.default.copyItem(at: url, to: backup)
        }
    }

    static func apply(_ profile: DisplayCanvasProfile) throws {
        let (url, dict) = try readOrCreate()
        if FileManager.default.fileExists(atPath: url.path) {
            try ensureBackup(for: url)
        }
        dict["canvas_width"] = profile.width
        dict["canvas_height"] = profile.height
        try write(dict, to: url)
    }

    static func revert() throws {
        let backup = backupURL()
        guard let url = existingURL, FileManager.default.fileExists(atPath: backup.path) else {
            throw CanvasPlistError.backupNotFound
        }
        let data = try Data(contentsOf: backup)
        let tempURL = url.deletingLastPathComponent()
            .appendingPathComponent(".\(url.lastPathComponent).restore.\(UUID().uuidString).tmp")
        try data.write(to: tempURL, options: [.withoutOverwriting])
        defer { try? FileManager.default.removeItem(at: tempURL) }
        _ = try FileManager.default.replaceItemAt(url, withItemAt: tempURL)
    }

    static func currentSize() -> String? {
        guard let (_, dict) = try? read(),
              let width = dict["canvas_width"] as? Int,
              let height = dict["canvas_height"] as? Int else {
            return nil
        }
        return "\(width) × \(height)"
    }
}

enum CanvasPlistError: LocalizedError {
    case fileNotFound
    case directoryNotFound
    case invalidPlist
    case backupNotFound

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "找不到 IOMobileGraphicsFamily.plist，或当前系统不允许访问。"
        case .directoryNotFound:
            return "当前 iOS 版本没有可用的受管偏好设置目录。"
        case .invalidPlist:
            return "IOMobileGraphicsFamily.plist is not a valid property list."
        case .backupNotFound:
            return "No saved canvas backup is available."
        }
    }
}
