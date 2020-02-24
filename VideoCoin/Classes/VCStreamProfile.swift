//
//  StreamEntity.swift
//  orbital
//
//  Created by Ryoichiro Oka on 11/10/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation

public struct VCStreamProfile: Codable {
    public let id: String
    public let name: String
    public let description: String
    public let is_enabled: Bool
    
}

public struct VCStreamProfileList: Codable {
    public let items: [VCStreamProfile]
}
