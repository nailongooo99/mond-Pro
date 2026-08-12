//
//  mg.swift
//  mond
//
//  Created by ruter on 16.07.26.
//

import Foundation
import Darwin
import MachO
import UIKit

func cache_data_offset(_ key: String) -> Int {
    let lib_mg = "/usr/lib/libMobileGestalt.dylib"
    dlopen(lib_mg, RTLD_GLOBAL)

    var header: UnsafePointer<mach_header_64>?
    for i in 0..<_dyld_image_count() {
        if String(cString: _dyld_get_image_name(i)) == lib_mg {
            header = unsafeBitCast(_dyld_get_image_header(i), to: UnsafePointer<mach_header_64>.self)
            break
        }
    }
    guard let header else { return 0 }

    var text_size = 0
    let cstr = getsectiondata(header, "__TEXT", "__cstring", &text_size)!.withMemoryRebound(to: CChar.self, capacity: text_size) { $0 }

    var key_ptr = cstr
    while Int(key_ptr - cstr) < text_size {
        if String(cString: key_ptr) == key { break }
        key_ptr += strlen(key_ptr) + 1
    }

    var const_size = 0
    var ptr = getsectiondata(header, "__AUTH_CONST", "__const", &const_size)?.withMemoryRebound(to: UInt.self, capacity: const_size / 8) { $0 }
    if ptr == nil {
        ptr = getsectiondata(header, "__DATA_CONST", "__const", &const_size)?.withMemoryRebound(to: UInt.self, capacity: const_size / 8) { $0 }
    }
    
    guard let ptr else { return 0 }
    for i in 0..<const_size / 8 {
        if ptr[i] == UInt(bitPattern: key_ptr) {
            return Int((ptr.advanced(by: i).withMemoryRebound(to: UInt16.self, capacity: 1) { $0[0x9a / 2] }) << 3)
        }
    }
    
    return 0
}

func grant_mg_write() -> Int64 {
    if UserDefaults.standard.string(forKey: "method") == "cmg" {
        return cmg()
    }

    var path_c = TweakPaths.gestalt_dir.utf8CString.map { Int8($0) }
    let handle = bad_query(&path_c, false, nil, false)
    switch handle {
        case -1:
            print("(bq) failed to resolve one or more functions")
        case -2:
            print("(bq) failed to create sandbox query")
        case -3:
            print("(bq) outside of containermanager's sandbox")
        case -4:
            print("(bq) kernel rejected sandbox query")
        default:
            print("(bq) granted mobilegestalt.plist access! handle: \(handle)")
    }
    
    return handle
}
