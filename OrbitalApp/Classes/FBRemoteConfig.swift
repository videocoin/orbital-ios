//
//  FBRemoteConfig.swift
//  OrbitalApp
//
//  Created by Ryoichiro Oka on 12/28/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import Firebase
import PromiseKit

enum FBRemoteConfigError : Error {
    case error(keyNotFound: FBRemoteConfigKey)
}

enum FBRemoteConfigKey : String {
    case DEFAULT_LIVE_CAST_TIME_LIMIT_IN_SEC
    case IOS_STREAM_PROFILE_ID
    case API_KEY
    case API_KEY_PROD
}

class FBRemoteConfig {
    // singleton because RemoteConfig is singleton too :(
    static let shared = FBRemoteConfig()
    
    private(set) var DEFAULT_LIVE_CAST_TIME_LIMIT_IN_SEC: Int!
    private(set) var IOS_STREAM_PROFILE_ID: String!
    private(set) var API_KEY: String!
    private(set) var API_KEY_PROD: String!
    
    private init() {}
    
    func updateSnapshot() -> Promise<Void> {
        let remoteConfig = RemoteConfig.remoteConfig()
        let remoteConfigSettings = RemoteConfigSettings()
        remoteConfigSettings.minimumFetchInterval = 0
        remoteConfig.configSettings = remoteConfigSettings
        
        return firstly {
            remoteConfig.fetchAndActivatePromise()
        }.map { _ in
            try self.setValues()
        }
    }
    
    private func setValues() throws {
        DEFAULT_LIVE_CAST_TIME_LIMIT_IN_SEC = try configValue(FBRemoteConfigKey.DEFAULT_LIVE_CAST_TIME_LIMIT_IN_SEC) { $0.numberValue?.intValue }
        IOS_STREAM_PROFILE_ID = try configValue(FBRemoteConfigKey.IOS_STREAM_PROFILE_ID) { $0.stringValue }
        API_KEY = try configValue(FBRemoteConfigKey.API_KEY) { $0.stringValue }
        API_KEY_PROD = try configValue(FBRemoteConfigKey.API_KEY_PROD) { $0.stringValue }
        
        //debugPrint("\(DEFAULT_LIVE_CAST_TIME_LIMIT_IN_SEC) \(ANDROID_STREAM_PROFILE_ID) \(API_KEY) \(API_KEY_PROD)")
    }
    
    private func configValue<T>(_ key: FBRemoteConfigKey, _ unraw: (RemoteConfigValue) -> T?) throws -> T {
        let raw = RemoteConfig.remoteConfig().configValue(forKey: key.rawValue)
        guard let value = unraw(raw) else {
            throw FBRemoteConfigError.error(keyNotFound: key)
        }

        return value
    }
}
