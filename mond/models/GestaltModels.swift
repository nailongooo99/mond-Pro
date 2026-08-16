import Foundation

struct EditableGestaltPlist {
    var dict: [String: Any]

    var topLevelKeys: [String] { dict.keys.sorted() }
    var cacheExtra: [String: Any] {
        get { dict["CacheExtra"] as? [String: Any] ?? [:] }
        set { dict["CacheExtra"] = newValue }
    }
    var cacheExtraKeys: [String] { cacheExtra.keys.sorted() }

    func value(forKey key: String) -> Any? { dict[key] }
    func cacheValue(forKey key: String) -> Any? { cacheExtra[key] }

    mutating func setValue(_ value: Any, forKey key: String) { dict[key] = value }
    mutating func setCacheValue(_ value: Any, forKey key: String) {
        var values = cacheExtra
        values[key] = value
        cacheExtra = values
    }
    mutating func removeCacheValue(forKey key: String) {
        var values = cacheExtra
        values.removeValue(forKey: key)
        cacheExtra = values
    }
}

enum EditablePlistValueKind: String, CaseIterable, Identifiable {
    case string, integer, float, boolean, data, array, dictionary

    var id: String { rawValue }
    var title: String {
        switch self {
        case .string: return "字符串"
        case .integer: return "整数"
        case .float: return "小数"
        case .boolean: return "布尔值"
        case .data: return "数据"
        case .array: return "数组"
        case .dictionary: return "字典"
        }
    }

    static func kind(of value: Any?) -> EditablePlistValueKind {
        switch value {
        case is String: return .string
        case let number as NSNumber:
            return CFGetTypeID(number) == CFBooleanGetTypeID() ? .boolean : (CFNumberIsFloatType(number) ? .float : .integer)
        case is Data: return .data
        case is [Any], is NSArray: return .array
        case is [String: Any], is NSDictionary: return .dictionary
        default: return .string
        }
    }
}

enum EditablePlistValueError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}

struct EditablePlistValueInfo {
    let kind: EditablePlistValueKind
    let summary: String
    let encoded: String

    static func info(for value: Any?) -> EditablePlistValueInfo {
        let kind = EditablePlistValueKind.kind(of: value)
        let encoded = encode(value, as: kind)
        let summary: String
        switch kind {
        case .string: summary = encoded.isEmpty ? "空字符串" : encoded
        case .integer, .float, .boolean: summary = encoded
        case .data: summary = "数据（\((value as? Data)?.count ?? 0) 字节）"
        case .array: summary = "数组（\((value as? [Any])?.count ?? (value as? NSArray)?.count ?? 0) 项）"
        case .dictionary: summary = "字典（\((value as? [String: Any])?.count ?? (value as? NSDictionary)?.count ?? 0) 项）"
        }
        return EditablePlistValueInfo(kind: kind, summary: summary, encoded: encoded)
    }

    static func encode(_ value: Any?, as kind: EditablePlistValueKind) -> String {
        switch kind {
        case .string: return value as? String ?? ""
        case .integer, .float: return (value as? NSNumber)?.stringValue ?? ""
        case .boolean: return (value as? NSNumber)?.boolValue == true ? "true" : "false"
        case .data: return (value as? Data)?.base64EncodedString() ?? ""
        case .array, .dictionary:
            guard let value, JSONSerialization.isValidJSONObject(value),
                  let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]) else { return "" }
            return String(data: data, encoding: .utf8) ?? ""
        }
    }

    static func parse(_ text: String, as kind: EditablePlistValueKind) throws -> Any {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .string: return text
        case .integer:
            guard let value = Int64(trimmed) else { throw EditablePlistValueError.invalid("请输入有效整数。") }
            return NSNumber(value: value)
        case .float:
            guard let value = Double(trimmed) else { throw EditablePlistValueError.invalid("请输入有效小数。") }
            return NSNumber(value: value)
        case .boolean:
            if ["true", "1", "yes"].contains(trimmed.lowercased()) { return NSNumber(value: true) }
            if ["false", "0", "no"].contains(trimmed.lowercased()) { return NSNumber(value: false) }
            throw EditablePlistValueError.invalid("请输入 true 或 false。")
        case .data:
            guard let data = Data(base64Encoded: trimmed) else { throw EditablePlistValueError.invalid("请输入有效的 Base64 数据。") }
            return data
        case .array:
            return try jsonObject(trimmed, expected: NSArray.self)
        case .dictionary:
            return try jsonObject(trimmed, expected: NSDictionary.self)
        }
    }

    private static func jsonObject<T>(_ text: String, expected: T.Type) throws -> Any {
        guard let data = text.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data), object is T else {
            throw EditablePlistValueError.invalid("JSON 类型与所选类型不匹配。")
        }
        return object
    }
}

func normalizedPlistValue(_ value: Any) -> Any {
    if let dictionary = value as? NSDictionary {
        var result: [String: Any] = [:]
        for (key, item) in dictionary {
            if let key = key as? String { result[key] = normalizedPlistValue(item) }
        }
        return result
    }
    if let dictionary = value as? [String: Any] {
        return dictionary.mapValues(normalizedPlistValue)
    }
    if let array = value as? NSArray {
        return array.map { normalizedPlistValue($0) }
    }
    if let array = value as? [Any] {
        return array.map(normalizedPlistValue)
    }
    return value
}
