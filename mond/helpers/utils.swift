//
//  utils.swift
//  mond
//
//  Created by ruter on 18.07.26.
//

import Darwin
import Foundation
import UIKit

func is_debugged() -> Bool {
    var info = kinfo_proc()
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride

    let rc = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
    if rc != 0 { return false }

    let P_TRACED: Int32 = 0x00000800
    return (info.kp_proc.p_flag & P_TRACED) != 0
}

func is_supported() -> Bool {
    let v = ProcessInfo.processInfo.operatingSystemVersion

    return v.majorVersion == 27 &&
           v.minorVersion == 0 &&
           v.patchVersion == 0
}

func hasHomeButton() -> Bool {
    let windows = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }

    return windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.bottom ?? 0 > 0
}

enum AppPaths {
    static var backups: String {
        let url = backupsURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url.path
    }

    private static var backupsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseURL.appendingPathComponent("backups", isDirectory: true)
    }

    static var tendies: String {
        let url = tendiesURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url.path
    }

    private static var tendiesURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseURL.appendingPathComponent("tendies", isDirectory: true)
    }
}

enum TweakPaths {
    static var gestalt = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
    static var gestalt_dir = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/"

    // iOS may expose this managed-preferences plist with either path spelling.
    // Prefer the canonical path used by Nugget, while retaining the private path
    // for builds/devices that expose it there.
    static let canvasPlistCandidates = [
        "/var/Managed Preferences/mobile/com.apple.iokit.IOMobileGraphicsFamily.plist",
        "/private/var/Managed Preferences/mobile/com.apple.iokit.IOMobileGraphicsFamily.plist",
        "/var/mobile/Library/Preferences/com.apple.iokit.IOMobileGraphicsFamily.plist",
        "/private/var/mobile/Library/Preferences/com.apple.iokit.IOMobileGraphicsFamily.plist"
    ]
}

func list_containers(_ root: String) -> [String] {
    var normalized = root
    if normalized.hasPrefix("/private/") { normalized.removeFirst("/private/".count - 1) }
    if normalized.hasSuffix("/") { normalized.removeLast() }
    var path = normalized.utf8CString.map { Int8($0) }
    guard let raw = bad_query_list(&path, 2_000_000) else { return [] }
    defer { free(raw) }
    return String(cString: raw).split(whereSeparator: \.isNewline).map(String.init).filter { !$0.isEmpty }
}

func is_pb_archive(_ url: URL) -> Bool {
    ["tendies", "zip"].contains(url.pathExtension.lowercased())
}
