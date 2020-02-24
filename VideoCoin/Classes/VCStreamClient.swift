//
//  CloudSource.swift
//  orbital
//
//  Created by Ryoichiro Oka on 11/9/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import SwiftyJSON

public enum VCStreamClientError: LocalizedError {
    case server(message: String) // direct message from server
    case state(message: String) // invalid operation per server state
    case timeout // ping timeout
    case pingCancelled // cancelld by user
    
    public var errorDescription: String? {
        switch self {
        case .server(message: let msg): return "Server returned an error message: \(msg)"
        case .state(message: let msg): return "Server is in an invalid state: \(msg)"
        case .timeout: return "Server connection timed out"
        case .pingCancelled: return "Ping cancelled by user"
        }
    }
}

public class VCStreamClient {
    let host: String
    public var accessToken: String?
    
    public init(host: String) {
        self.host = host
    }
    
    private func headers() -> HTTPHeaders {
        [ "Authorization": "Bearer \(self.accessToken ?? "")" ]
    }
    
    private func throwIfErrorMessage(_ data: Data) throws {
        if let error = try? data.decodeJson(for: VCStreamErrorResponse.self) {
            throw VCStreamClientError.server(message: error.message)
        }
    }
    
    public func fetchStreamProfiles() -> Promise<[VCStreamProfile]> {
        let url = "\(host)/api/v1/profiles"
        
        return firstly {
            Alamofire.request(url).responseData()
        }.map { rsp in
            try self.throwIfErrorMessage(rsp.data)
            let profiles = try rsp.data.decodeJson(for: VCStreamProfileList.self)!
            return profiles.items
        }
    }
    
    public func createStream(_ request: VCStreamCreateRequest) -> Promise<VCStreamSnapshot> {
        debugPrint("VCStreamClient.createStream()")
        
        let url = "\(host)/api/v1/streams"
        let args = [
            "name": request.name,
            "profile_id": request.profile_id,
        ]
        
        debugPrint(self.accessToken ?? "empty access token")
        
        return firstly {
            Alamofire.request(url, method: .post, parameters: args, encoding: JSONEncoding.default, headers: self.headers()).responseData()
        }.map { rsp in
            try self.throwIfErrorMessage(rsp.data)
            return try rsp.data.decodeJson(for: VCStreamSnapshot.self)!
        }
    }
    
    public func runStream(_ streamId: String) -> Promise<VCStreamSnapshot> {
        debugPrint("VCStreamClient.runStream()")
        
        let url = "\(host)/api/v1/streams/\(streamId)/run"
        
        return firstly {
            Alamofire.request(url, method: .post, headers: self.headers()).responseData()
        }.map { rsp in
            try self.throwIfErrorMessage(rsp.data)
            return try rsp.data.decodeJson(for: VCStreamSnapshot.self)!
        }
    }
    
    public func pingStream(_ streamId: String, cancelled: (() -> Bool)? = nil) -> Promise<VCStreamSnapshot> {
        let url = "\(host)/api/v1/streams/\(streamId)"
        
        return firstly {
            Alamofire.request(url, method: .get, headers: self.headers()).responseData()
        }.map { rsp in
            try self.throwIfErrorMessage(rsp.data)
            return try rsp.data.decodeJson(for: VCStreamSnapshot.self)!
        }.get { _ in
            if cancelled?() ?? false {
                throw VCStreamClientError.pingCancelled
            }
        }
    }
    
    public func pingUntilPrepared(_ streamId: String, count: Int, interval: DispatchTimeInterval, cancelled: (() -> Bool)? = nil) -> Promise<VCStreamSnapshot> {
        firstly {
            self.pingStream(streamId, cancelled: cancelled)
        }.map { stream throws -> VCStreamSnapshot? in
            if count == 0 {
                throw VCStreamClientError.timeout
            }
            
            switch stream.status {
            case .STREAM_STATUS_NEW:
                throw VCStreamClientError.state(message: "Stream not running")
            case .STREAM_STATUS_COMPLETED:
                throw VCStreamClientError.state(message: "Stream has completed")
            case .STREAM_STATUS_FAILED:
                throw VCStreamClientError.state(message: "Stream has failed")
            case .STREAM_STATUS_PREPARING,
                 .STREAM_STATUS_NONE: // I don't know what this state signifies but it's harmless
                debugPrint("Stream preparing: \(stream.status)")
                return nil
            case .STREAM_STATUS_PREPARED,
                 .STREAM_STATUS_PENDING,
                 .STREAM_STATUS_READY:
                debugPrint("Stream ready")
                return stream
            }
        }.then { stream -> Promise<VCStreamSnapshot> in
            if let stream = stream {
                return Promise.value(stream)
            }
            
            return after(interval).then { _ in
                self.pingUntilPrepared(streamId, count: count - 1, interval: interval, cancelled: cancelled)
            }
        }
    }
    
    public func pingUntilReady(_ streamId: String, count: Int, interval: DispatchTimeInterval, cancelled: (() -> Bool)? = nil) -> Promise<VCStreamSnapshot> {
        firstly {
            self.pingStream(streamId, cancelled: cancelled)
        }.map { stream throws -> VCStreamSnapshot? in
            if count == 0 {
                throw VCStreamClientError.timeout
            }
            
            switch stream.status {
            case .STREAM_STATUS_NEW:
                throw VCStreamClientError.state(message: "Stream not running")
            case .STREAM_STATUS_COMPLETED:
                throw VCStreamClientError.state(message: "Stream has completed")
            case .STREAM_STATUS_FAILED:
                throw VCStreamClientError.state(message: "Stream has failed")
            case .STREAM_STATUS_PREPARING,
                 .STREAM_STATUS_NONE:
                throw VCStreamClientError.state(message: "Stream is still preparing")
            case .STREAM_STATUS_PREPARED,
                 .STREAM_STATUS_PENDING:
                debugPrint("Stream pending: \(stream.status)")
                return nil
            case .STREAM_STATUS_READY:
                debugPrint("Stream ready")
                return stream
            }
        }.then { stream -> Promise<VCStreamSnapshot> in
            if let stream = stream {
                return Promise.value(stream)
            }
            
            return after(interval).then { stream in
                self.pingUntilReady(streamId, count: count - 1, interval: interval, cancelled: cancelled)
            }
        }
    }
    
    public func stopStream(_ streamId: String) -> Promise<VCStreamSnapshot> {
        let url = "\(host)/api/v1/streams/\(streamId)/stop"
        
        return firstly {
            Alamofire.request(url, method: .post, headers: self.headers()).responseData()
        }.map { rsp in
            try self.throwIfErrorMessage(rsp.data)
            return try rsp.data.decodeJson(for: VCStreamSnapshot.self)!
        }
    }
}

extension String {
    func decodeJson<T>(for type: T.Type) throws -> T where T : Decodable {
        try JSONDecoder().decode(type, from: self.data(using: .utf8)!)
    }
}

extension Data {
    func decodeJson<T>(for type: T.Type) throws -> T? where T : Decodable {
        if let jsonStr = String(data: self, encoding: .utf8) {
            return try jsonStr.decodeJson(for: type)
        }
        
        return nil
    }
}
