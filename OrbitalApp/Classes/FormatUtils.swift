//
//  FormatUtils.swift
//  orbital
//
//  Created by Ryoichiro Oka on 11/9/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation

struct FormatUtils {
    static func decode<T>(_ type: T.Type, from: String) throws -> T where T: Decodable {
        try JSONDecoder().decode(type, from: from.data(using: .utf8)!)
    }
    
    static func encode<T>(from: T) throws -> String where T: Encodable {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encoded = try encoder.encode(from)
        return String(data: encoded, encoding: .utf8)!
    }
}

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        return json as! [String: Any]
    }
}

extension Dictionary where Key == String, Value == Any {
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        let json = try JSONSerialization.data(withJSONObject: self, options: [])
        return try JSONDecoder().decode(type, from: json)
    }
}
