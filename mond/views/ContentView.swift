//
//  ContentView.swift
//  mond
//
//  Created by ruter on 16.07.26.
//

import SwiftUI
import PartyUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @AppStorage("mg_devicename") private var mg_devicename: String = ""
    @AppStorage("token") private var token: String = ""
    
    @State private var mg_dict_now: NSMutableDictionary = NSMutableDictionary()
    @State private var is_valid: Bool = false
    
    @State private var subtype: Int = 0
    @State private var og_subtype: Int = 0
    @State private var og_devicename: String = ""
    @State private var enable_devicename: Bool = false
    @State private var product_type: String = ""

    // Dynamic Island artwork and display geometry are separate tweaks.
    // Keep the canvas fix opt-in because it changes the system resolution.
    @State private var enable_canvas_fix: Bool = false
    @State private var canvas_size: String? = nil
    
    @State private var show_settings: Bool = false
    @State private var show_new_tools_info: Bool = false
    @State private var is_applying: Bool = false
    
    private var mg_valid: Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: TweakPaths.gestalt)) else { return false }
        return (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) != nil
    }
    
    private var mg_empty: Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: TweakPaths.gestalt),
              let size = attributes[.size] as? UInt64 else { return false }

        return size == 0
    }
    
    var valid: Bool {
        (sandbox_extension_consume(token) ?? -1) >= 0
    }
    
    var body: some View {
        TabView {
        NavigationStack {
            List {
                if !mg_valid || mg_empty {
                    Section {
                        if mg_empty {
                            PlainAlert(title: "请勿重启！", icon: "exclamationmark.triangle.fill", text: "MobileGestalt.plist 似乎为空。", color: Color.yellow)
                        }
                        
                        if !mg_valid {
                            PlainAlert(title: "请勿重启！", icon: "exclamationmark.triangle.fill", text: "MobileGestalt.plist 似乎无效。", color: Color.yellow)
                        }
                    } header: {
                        Label("警告", systemImage: "exclamationmark.triangle")
                    } footer: {
                        Text("现在重启可能导致设备陷入启动循环。请先点击“恢复修改”；如果警告仍未消失，请不要重启设备，并查看日志。")
                    }
                }
                
                Section {
                    NavigationLink {
                        PosterView()
                    } label: {
                        Label("墙纸与 PosterBoard", systemImage: "photo.on.rectangle")
                    }
                    NavigationLink {
                        SantanderView()
                    } label: {
                        Label("文件管理", systemImage: "folder")
                    }
                    Button {
                        show_new_tools_info = true
                    } label: {
                        Label("新增工具说明", systemImage: "info.circle")
                    }
                } header: {
                    Label("新增工具", systemImage: "sparkles")
                }

                Section {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            is_applying = true
                        }
                        mg_apply()
                    } label: {
                        HStack {
                            if is_applying {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(is_applying ? "正在应用…" : "应用修改")
                        }
                    }
                    .disabled(is_applying)
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            is_applying = true
                        }
                        mg_revert()
                    } label: {
                        HStack {
                            if is_applying {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text("恢复修改")
                        }
                    }
                    .disabled(is_applying)
                } footer: {
                    Text("**警告：** 这些修改可能影响设备功能；使用不当还可能导致设备无法正常启动！")
                }
                
                Section {
                    Picker(selection: $subtype) {
                        Text("原始设置（\(og_subtype)）").tag(og_subtype)
                        if is_device_good() {
                            Text("关闭灵动岛").tag(2436)
                        }
                        Text("iPhone 14 Pro").tag(2556)
                        Text("iPhone 14 Pro Max").tag(2796)
                        Text("iPhone 15 Pro Max").tag(2976)
                        if doubleSystemVersion() >= 18.0 {
                            Text("iPhone 16 Pro").tag(2622)
                            Text("iPhone 16 Pro Max").tag(2868)
                        }
                        if doubleSystemVersion() >= 26.0 {
                            Text("iPhone Air").tag(2736)
                        }
                        if hasHomeButton() {
                            Text("iPhone X 手势").tag(2436)
                        }
                    } label: {
                        HStack {
                            Text("设备子类型")
                            Spacer()
                        }
                    }
                    
                    Toggle("自定义设备名称", isOn: $enable_devicename)
                    
                    if enable_devicename {
                        TextField("设备名称", text: $mg_devicename)
                    }

                    if DisplayCanvasProfile.forSubtype(subtype) != nil {
                        Toggle("灵动岛状态栏 / 画布修复", isOn: $enable_canvas_fix)
                            .onChange(of: enable_canvas_fix) { _, enabled in
                                if !enabled {
                                    try? CanvasPlistStore.revert()
                                    canvas_size = CanvasPlistStore.currentSize()
                                }
                            }
                        if enable_canvas_fix {
                            let profile = DisplayCanvasProfile.forSubtype(subtype)!
                            VStack(alignment: .leading, spacing: 4) {
                                Text("目标画布：\(profile.width) × \(profile.height)")
                                    .font(.subheadline)
                                Text("将 canvas_width / canvas_height 写入 IOMobileGraphicsFamily.plist。它独立于 MobileGestalt 外观设置，可能需要重启后生效。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let canvas_size {
                            Text("当前画布：\(canvas_size)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("设备外观", systemImage: "paintbrush.pointed")
                }
                
                // basic tweak toggles
                Section {
                    PlainToggle(text: "灵动岛", minSupportedVersion: 19.0, isOn: mg_key_binding(["YlEtTtHlNesRBMal1CqRaA"]))
                    PlainToggle(text: "全天候显示",  minSupportedVersion: 18.0, isOn: mg_key_binding(["j8/Omm6s1lsmTDFsXjsBfA", "2OOJf1VhaM7NxfRok3HbWQ"]))
                    PlainToggle(text: "全天候显示鲜艳度", minSupportedVersion: 18.0, isOn: mg_key_binding(["ykpu7qyhqFweVMKtxNylWA"]))
                    PlainToggle(text: "充电上限", minSupportedVersion: 17.0, isOn: mg_key_binding(["37NVydb//GP/GrhuTN+exg"]))
                    PlainToggle(text: "开机提示音", isOn: mg_key_binding(["QHxt+hGLaBPbQJbXiUJX3w"]))
                    PlainToggle(text: "Liquid Glass 低电量模式", minSupportedVersion: 19.0, isOn: mg_key_binding(["SAGvsp6O6kAQ4fEfDJpC4Q"]))
                } header: {
                    Label("软件功能", systemImage: "gearshape")
                }
                
                Section {
                    PlainToggle(text: "相机控制", minSupportedVersion: 18.0, isOn: mg_key_binding(["CwvKxM2cEogD3p+HYgaW0Q", "oOV1jhJbdV3AddkcCg0AEA"]))
                    PlainToggle(text: "操作按钮", minSupportedVersion: 17.0, isOn: mg_key_binding(["cT44WE1EohiwRzhsZ8xEsw"]))
                    PlainToggle(text: "车祸检测", isOn: mg_key_binding(["HCzWusHQwZDea6nNhaKndw"]))
                    if hasHomeButton() {
                        PlainToggle(text: "轻点唤醒", isOn: mg_key_binding(["yZf3GTRMGTuwSV/lD7Cagw"]))
                    }
                    PlainToggle(text: "PWM 调光", minSupportedVersion: 19.0, isOn: mg_key_binding(["6IejgN+1Fmu5/QrZFOIeNw"]))
                } header: {
                    Label("硬件功能", systemImage: "iphone")
                }
                
                Section {
                    PlainToggle(text: "安全研究设备界面", minSupportedVersion: 26.0, isOn: mg_key_binding(["XYlJKKkj2hztRP1NWWnhlw"]))
                    
                    PlainToggle(
                        text: "解除地区限制",
                        infoType: .info,
                        infoMessage: "此修改在部分 iOS 版本或设备上可能无效。",
                        isOn: mg_region_restrict_binding()
                    )
                    
                    PlainToggle(
                        text: "Apple Intelligence",
                        infoType: .info,
                        infoMessage: "Apple Intelligence 目前可能无法正常启用。",
                        minSupportedVersion: 18.1,
                        isOn: mg_key_binding(["A62OafQ85EJAiiqKn4agtg"])
                    )
                    
                    HStack(spacing: 10) {
                        Picker("设备伪装", selection: $product_type) {
                            Text("默认").tag(machine_name())
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                if doubleSystemVersion() >= 17.4 {
                                    Text("iPad Pro 11-inch (M4)").tag("iPad16,3")
                                    Text("iPad Pro 11-inch (M4, Cellular)").tag("iPad16,4")
                                }
                                Text("iPad Pro 11-inch (4th Gen)").tag("iPad14,3")
                                Text("iPad Pro 11-inch (4th Gen, Cellular)").tag("iPad14,4")
                            } else {
                                Text("iPhone 15 Pro").tag("iPhone16,1")
                                Text("iPhone 15 Pro Max").tag("iPhone16,2")
                                if doubleSystemVersion() >= 18.0 {
                                    Text("iPhone 16").tag("iPhone17,3")
                                    Text("iPhone 16 Plus").tag("iPhone17,4")
                                    Text("iPhone 16 Pro").tag("iPhone17,1")
                                    Text("iPhone 16 Pro Max").tag("iPhone17,2")
                                }
                                if doubleSystemVersion() >= 19.0 {
                                    Text("iPhone 17").tag("iPhone18,3")
                                    Text("iPhone 17 Pro").tag("iPhone18,1")
                                    Text("iPhone 17 Pro Max").tag("iPhone18,2")
                                    Text("iPhone Air").tag("iPhone18,4")
                                }
                            }
                        }
                        
                        Button {
                            Alertinator.shared.alert(
                                title: "设备伪装说明",
                                body: "只有在需要下载 Apple Intelligence 时才建议伪装设备型号。此操作可能影响 Face ID。如果取消伪装后仍想保留 Apple Intelligence，请不要再次进入“设置”中的“Apple Intelligence 与 Siri”页面。"
                            )
                        } label: {
                            Image(systemName: "info.circle")
                                .frame(width: 24, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Label("资格与兼容性", systemImage: "checklist")
                }
                
                Section {
                    let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary
                    
                    PlainToggle(text: "允许安装 iPadOS 应用", isOn: mg_key_binding(["9MZ5AdH43csAUajl/dU+IQ"], type: [Int].self, default_val: [1], on_val: [1, 2]))
                    PlainToggle(text: "Apple Pencil 设置", isOn: mg_key_binding(["yhHcB0iH0d1XzPO/CFd3ow"]))
                    
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        PlainToggle(text: "台前调度", isOn: mg_key_binding(["qeaj75wk3HF4DwQ8qbIi7g"]))
                    }
                    PlainToggle(
                        text: "iPadOS 界面",
                        infoType: .warning,
                        infoMessage: "这是一个高风险修改。如果你使用字母数字密码，请不要启用。请勿关闭“台前调度中显示程序坞”，否则设备横屏旋转时可能陷入启动循环。部分用户反馈，启用 iPadOS 界面后点击台前调度可能使设备进入恢复模式。启用后还可能出现系统不稳定、应用数据异常消失等问题。",
                        isOn: mg_trollpad_binding()
                    )
                    .disabled(cache_extra?["+3Uf0Pm5F8Xy7Onyvko0vA"] as? String != "iPhone")
                } header: {
                    Label("iPadOS 功能", systemImage: "ipad")
                }
                
                Section {
                    PlainToggle(text: "内部存储", isOn: mg_key_binding(["LBJfwOEzExRxzlAnSuI7eg"]))
                    PlainToggle(text: "内部功能", isOn: mg_internal_binding())
                    PlainToggle(text: "在所有应用中显示 Metal HUD", isOn: mg_key_binding(["EqrsVvjcYDdxHBiQmGhAWw"]))
                } header: {
                    Label("内部功能", systemImage: "ant")
                }
            }
            .navigationTitle("mond Pro")
            .tint(Color("AccentColor"))
            .onAppear {
                if !valid {
                    state.exploit_succeeded = grant_mg_write() >= 0
                } else {
                    print("(mond) valid token saved, skipping exploit")
                    state.exploit_succeeded = true
                }
                
                mg_load()
                canvas_size = CanvasPlistStore.currentSize()
            }
            .onChange(of: subtype) { _, newSubtype in
                // Changing artwork subtype updates the suggested target only;
                // users must explicitly opt into the resolution-changing fix.
                if let profile = DisplayCanvasProfile.forSubtype(newSubtype) {
                    canvas_size = "\(profile.width) × \(profile.height)"
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            show_settings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $show_settings) {
                SettingsView()
            }
        }
        .sheet(isPresented: $show_new_tools_info) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("新增工具说明").font(.title2.bold())
                        Text("墙纸与 PosterBoard：导入或下载 .tendies 壁纸包，应用后按提示打开并关闭 PosterBoard 使更改生效。")
                        Text("文件管理：浏览应用容器中的文件，支持文本预览、图片/媒体查看以及在获得授权后保存文件。")
                        Text("使用建议：一次少量导入壁纸包；如果页面长时间加载，请检查网络和利用方法授权状态，并查看日志。")
                        Text("这些功能依赖 iOS beta 的沙盒路径和权限行为，具体可用性取决于设备、系统版本和授权结果。")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("工具说明")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .tabItem { Label("工具", systemImage: "switch.2") }

        AdvancedGestaltEditorView(dictionary: $mg_dict_now, isBusy: $is_applying)
            .tabItem { Label("字段", systemImage: "list.bullet.rectangle") }

        BackupLibraryView(dictionary: $mg_dict_now, isBusy: $is_applying)
            .tabItem { Label("备份", systemImage: "archivebox") }
        }
    }
    
    private enum MGViewError: Error, LocalizedError {
        case missingArtworkSubtype
        case missingArtworkDeviceName
        
        var errorDescription: String? {
            switch self {
            case .missingArtworkSubtype:
                return "读取 ArtworkDeviceSubType 失败。"
            case .missingArtworkDeviceName:
                return "读取设备名称失败。"
            }
        }
    }
    
    private func mg_load() {
        do {
            let mg_url_now = URL(fileURLWithPath: TweakPaths.gestalt)
            mg_dict_now = try NSMutableDictionary(contentsOf: mg_url_now, error: ())
            
            // this'll cache gestalt and put it in a safe place
            let mg_url_saved = URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedGestalt.plist")
            
            if !FileManager.default.fileExists(atPath: mg_url_saved.path) {
                try FileManager.default.copyItem(at: mg_url_now, to: mg_url_saved)
            }
            
            // get original gestalt values
            let mg_saved_dict = try NSMutableDictionary(contentsOf: mg_url_saved, error: ())
            let og_cache_extra = mg_saved_dict["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            let og_artwork = og_cache_extra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            guard let ogSubtype = og_artwork["ArtworkDeviceSubType"] as? Int else { throw MGViewError.missingArtworkSubtype }
            og_subtype = ogSubtype
            
            guard let ogDeviceName = og_artwork["ArtworkDeviceProductDescription"] as? String else { throw MGViewError.missingArtworkDeviceName }
            
            // now get current gestalt values
            let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            let artwork = cache_extra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            subtype = artwork["ArtworkDeviceSubType"] as? Int ?? ogSubtype // fallback
            mg_devicename = artwork["ArtworkDeviceProductDescription"] as? String ?? ogDeviceName
            
            // assume it's been changed
            if mg_devicename != ogDeviceName {
                enable_devicename = true
            }
            
            if let productType = cache_extra["h9jDsbgj7xIVeIQ8S3/X3Q"] as? String, !productType.isEmpty {
                product_type = productType
            } else {
                product_type = machine_name()
            }
        } catch {
            print("(mg) failed to load data: \(error)")
            Alertinator.shared.alert(title: "读取 MobileGestalt 失败", body: "请重启应用后重试，并查看日志了解详细信息。")
        }
    }
    
    private func mg_apply() {
        do {
            let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            if !product_type.isEmpty {
                cache_extra["h9jDsbgj7xIVeIQ8S3/X3Q"] = product_type
            }
            
            let artwork_dict = cache_extra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            artwork_dict["ArtworkDeviceSubType"] = subtype
            if enable_devicename {
                artwork_dict["ArtworkDeviceProductDescription"] = mg_devicename
            }
            
            let data = try PropertyListSerialization.data(fromPropertyList: mg_dict_now, format: .xml, options: 0)

            try mg_write(data)

            // Artwork subtype does not resize the display by itself. Apply the
            // matching optional canvas/status-bar correction as a separate plist
            // update, mirroring the behavior of Nugget's RDAR fix. A missing
            // canvas plist must not undo the successful MobileGestalt write.
            var canvasWarning: String?
            if enable_canvas_fix, let profile = DisplayCanvasProfile.forSubtype(subtype) {
                do {
                    try CanvasPlistStore.apply(profile)
                    canvas_size = "\(profile.width) × \(profile.height)"
                    print("(resolution) applied canvas: \(profile.width)x\(profile.height)")
                } catch {
                    canvasWarning = error.localizedDescription
                    print("(resolution) canvas fix skipped: \(error)")
                }
            }

            mg_dict_now = NSMutableDictionary()
            enable_devicename = false
            withAnimation(.easeInOut(duration: 0.2)) {
                is_applying = false
            }

            print("(mg) successfully overwrote mobilegestalt!")
            let canvasMessage = canvasWarning.map { "\n\n画布修复已跳过：\($0)" } ?? ""
            Alertinator.shared.alert(title: "已应用 Gestalt 修改", body: "请重载 SpringBoard 使更改生效；部分修改可能需要重启设备。\(canvasMessage)", actionLabel: "重载 SpringBoard", action: {
                state.respring()
            })
        } catch {
            withAnimation(.easeInOut(duration: 0.2)) {
                is_applying = false
            }
            print("(mg) failed to apply mobilegestalt: \(error)")
            Alertinator.shared.alert(title: "应用修改失败", body: "MobileGestalt 修改未完成。请查看日志了解详细错误；如果启用了画布修复，系统可能不支持当前 plist 路径。")
        }
    }
    
    private func mg_revert() {
        do {
            let backup_url = URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedGestalt.plist")
            let backup_data = try Data(contentsOf: backup_url)
            try mg_write(backup_data)
            try? CanvasPlistStore.revert()
            canvas_size = CanvasPlistStore.currentSize()
            enable_canvas_fix = false
            withAnimation(.easeInOut(duration: 0.2)) {
                is_applying = false
            }

            print("(mg) successfully reverted mobilegestalt and canvas!")
            Alertinator.shared.alert(title: "已恢复 Gestalt 修改", body: "请重启设备使更改生效。")
        } catch {
            withAnimation(.easeInOut(duration: 0.2)) {
                is_applying = false
            }
            // The direct file write path now surfaces the underlying error through the catch.
            print("(mg) failed to revert mobilegestalt: \(error)")
            Alertinator.shared.alert(title: "恢复 MobileGestalt 失败", body: "请查看日志了解详细错误。")
        }
    }

    private func mg_write(_ data: Data) throws {
        let target_url = URL(fileURLWithPath: TweakPaths.gestalt)
        let temp_url = target_url.deletingLastPathComponent()
            .appendingPathComponent(".\(target_url.lastPathComponent).\(UUID().uuidString).tmp")

        try data.write(to: temp_url, options: [.withoutOverwriting])
        defer { try? fm.removeItem(at: temp_url) }

        if fm.fileExists(atPath: target_url.path) {
            _ = try fm.replaceItemAt(target_url, withItemAt: temp_url)
        } else {
            try fm.moveItem(at: temp_url, to: target_url)
        }
    }
    
    private func mg_key_binding(_ keys: [String]) -> Binding<Bool> {
        mg_key_binding(keys, type: Int.self, default_val: 0, on_val: 1)
    }

    private func mg_key_binding<T: Equatable>(_ keys: [String], type: T.Type, default_val: T, on_val: T) -> Binding<Bool> {
        guard let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }

        return Binding(get: {
            let value = cache_extra[keys.first!] as? T ?? default_val
            return value == on_val
        }, set: { enabled in
            for key in keys {
                if enabled {
                    cache_extra[key] = on_val
                } else {
                    cache_extra.removeObject(forKey: key)
                }
            }
        })
    }
    
    private func mg_trollpad_binding() -> Binding<Bool> {
        guard let cache_data = mg_dict_now["CacheData"] as? NSMutableData,
                let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        let value_off = cache_data_offset("mtrAoWJ3gsq+I90ZnQ0vQw")
        let keys = [
            "uKc7FPnEO++lVhHWHFlGbQ", // ipad
            "mG0AnH/Vy1veoqoLRAIgTA", // MedusaFloatingLiveAppCapability
            "UCG5MkVahJxG1YULbbd5Bg", // MedusaOverlayAppCapability
            "ZYqko/XM5zD3XBfN5RmaXA", // MedusaPinnedAppCapability
            "nVh/gwNpy7Jv1NOk00CMrw", // MedusaPIPCapability,
            "qeaj75wk3HF4DwQ8qbIi7g", // DeviceSupportsEnhancedMultitasking
        ]
        
        return Binding(get: {
            if let value = cache_extra[keys.first!] as? Int? {
                return value == 1
            }
            
            return false
        }, set: { enabled in
            if enabled {
                Alertinator.shared.alert(title: "警告", body: "这是一个高风险修改。如果你使用字母数字密码，请不要启用。请勿关闭“台前调度中显示程序坞”，否则设备横屏旋转时可能陷入启动循环。启用后可能出现系统不稳定或应用数据异常消失等问题。")
            }
            
            cache_data.mutableBytes.storeBytes(of: enabled ? 3 : 1, toByteOffset: value_off, as: Int.self)
            
            for key in keys {
                if enabled {
                    cache_extra[key] = 1
                } else {
                    cache_extra.removeObject(forKey: key)
                }
            }
        })
    }
    
    private func mg_region_restrict_binding() -> Binding<Bool> {
        guard let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        return Binding<Bool>(
            get: {
                return cache_extra["h63QSdBCiT/z0WU6rdQv6Q"] as? String == "US" &&
                    cache_extra["zHeENZu+wbg7PUprwNwBWg"] as? String == "LL/A"
            },
            set: { enabled in
                if enabled {
                    Alertinator.shared.alert(title: "警告", body: "请勿使用此功能绕过地区限制或规避当地法律（例如关闭相机快门声）。因启用此功能造成的后果需由用户自行承担。")
                    cache_extra["h63QSdBCiT/z0WU6rdQv6Q"] = "US"
                    cache_extra["zHeENZu+wbg7PUprwNwBWg"] = "LL/A"
                } else {
                    cache_extra.removeObject(forKey: "h63QSdBCiT/z0WU6rdQv6Q")
                    cache_extra.removeObject(forKey: "zHeENZu+wbg7PUprwNwBWg")
                }
            }
        )
    }
    
    private func mg_internal_binding() -> Binding<Bool> {
        guard let cache_data = mg_dict_now["CacheData"] as? NSMutableData else {
            return .constant(false)
        }
        
        let off_apple_internal_install = cache_data_offset("EqrsVvjcYDdxHBiQmGhAWw")
        let off_has_internal_settings_bundle = cache_data_offset("Oji6HRoPi7rH7HPdWVakuw")
        let off_internal_build = cache_data_offset("LBJfwOEzExRxzlAnSuI7eg")
        
        return Binding(
            get: {
                return cache_data.bytes.load(fromByteOffset: off_apple_internal_install, as: Int.self) == 1
            },
            set: { enabled in
                cache_data.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_apple_internal_install, as: Int.self)
                cache_data.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_has_internal_settings_bundle, as: Int.self)
                cache_data.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_internal_build, as: Int.self)
            }
        )
    }
    
    private func is_device_good() -> Bool {
        let supported: [String] = ["iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2", "iPhone17,3", "iPhone17,4", "iPhone17,1", "iPhone17,2", "iPhone18,3", "iPhone18,1", "iPhone18,2", "iPhone17,5"]
        
        if supported.contains(machine_name()) && doubleSystemVersion() < 19.0 {
            return true
        }
        
        return false
    }
    
    private func machine_name() -> String {
        var sys_info = utsname()
        uname(&sys_info)
        let machine_mirror = Mirror(reflecting: sys_info.machine)
        
        return machine_mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}
