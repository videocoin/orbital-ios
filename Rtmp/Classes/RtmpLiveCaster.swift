//
//  LiveCaster.swift
//  orbitalApp
//
//  Created by Ryoichiro Oka on 12/16/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import AVFoundation
import HaishinKit

public struct RtmpLiveCasterConfig {
    public let fps: Int
    public let videoCaptureResolution: AVCaptureSession.Preset
    public let videoStreamResolutionWidth: Int
    public let videoStreamResolutionHeight: Int
    public let videoStreamBitrateKbps: Int
    public let audioBitrateKbps: Int
    public let audioSampleRate: Double
    
    public static let defaultConfig = RtmpLiveCasterConfig(
        fps: 24,
        videoCaptureResolution: AVCaptureSession.Preset.hd1280x720,
        videoStreamResolutionWidth: 720,
        videoStreamResolutionHeight: 1280,
        videoStreamBitrateKbps: 1200,
        audioBitrateKbps: 64,
        audioSampleRate: 44_100)
}

public enum RtmpLiveCasterError : Error {
    case failed
    case failedWith(code: Event)
}

public protocol RtmpLiveCasterDelegate {
    func rtmpLiveCaster(onCapture error: Error)
    func rtmpLiveCaster(onConnection error: RtmpLiveCasterError)
    func rtmpLiveCasterConnectionSucceeded()
    func rtmpLiveCasterConnectionClosed()
}

public class RtmpLiveCaster {
    private let stream: RTMPStream!
    private let connection: RTMPConnection!
    
    private var destination: String!
    private var streamKey: String!
    
    public var delegate: RtmpLiveCasterDelegate?
    
    public init() {
        connection = RTMPConnection()
        stream = RTMPStream(connection: connection)
    }

    // Can capture both video and audio
    // as previously permitted by user.
    public func hasCaptureAuthsGranted() -> Bool {
        return
            AVCaptureDevice.authorizationStatus(for: .video) == .authorized &&
            AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
    
    // Cannot capture either video or audio
    // as one or both of their permissions have been denied by user.
    public func hasCaptureAuthsDenied() -> Bool {
        return
            AVCaptureDevice.authorizationStatus(for: .video) == .denied ||
            AVCaptureDevice.authorizationStatus(for: .audio) == .denied
    }
    
    public func requestCaptureAuths(for completionHandler: @escaping ((Bool) -> Void)) {
        if hasCaptureAuthsGranted() {
            completionHandler(true)
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video) { videoAuthGranted in
            AVCaptureDevice.requestAccess(for: .audio) { audioAuthGranted in
                completionHandler(videoAuthGranted && audioAuthGranted)
            }
        }
    }
    
    public func attachStream(view: GLHKView) {
        view.attachStream(stream)
    }
    
    public func configure(config: RtmpLiveCasterConfig) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setPreferredSampleRate(config.audioSampleRate)
        // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
        if #available(iOS 10.0, *) {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth])
        } else {
            session.perform(
                NSSelectorFromString("setCategory:withOptions:error:"),
                with: AVAudioSession.Category.playAndRecord,
                with: [AVAudioSession.CategoryOptions.allowBluetooth])
        }
        
        try session.setMode(AVAudioSession.Mode.default)
        try session.setActive(true)
        
        stream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            self.delegate?.rtmpLiveCaster(onCapture: error)
        }
        
        stream.captureSettings = [
            .fps: config.fps, // FPS
            .sessionPreset: config.videoCaptureResolution, // input video width/height
            .continuousAutofocus: true, // use camera autofocus mode
            .continuousExposure: true, //  use camera exposure mode
            //.preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
        ]
        
        stream.videoSettings = [
            .width: config.videoStreamResolutionWidth, // video output width
            .height: config.videoStreamResolutionHeight, // video output height
            .bitrate: config.videoStreamBitrateKbps * 1024, // video output bitrate
        ]
        
        stream.audioSettings = [
            .bitrate: config.audioBitrateKbps * 1024,
            .sampleRate: 0,
        ]
    }
    
    public func attachCamera(position: AVCaptureDevice.Position) {
        stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)) { error in
            self.delegate?.rtmpLiveCaster(onCapture: error)
        }
    }
    
    public func attachVideoFile(url: URL, onComplete: @escaping MP4Sampler.Handler) {
        stream.appendFile(url, completionHandler: onComplete)
    }
    
    public func connect(destination: String, streamKey: String) {
        self.destination = destination
        self.streamKey = streamKey
        
        connection.connect(destination)
        connection.addEventListener(.rtmpStatus, selector: #selector(onRtmpStatusChanged), observer: self)
        connection.addEventListener(.ioError, selector: #selector(onRtmpErrorIssued), observer: self)
    }

    public func connect(_ destination: String) {
        var components = destination.components(separatedBy: "/")
        let key = components.last!
        components.removeLast()
        let host = components.joined(separator: "/")
        connect(destination: host, streamKey: key)
    }
    
    public func disconnect() {
        stream.close()
        connection.close()
        connection.removeEventListener(.rtmpStatus, selector: #selector(onRtmpStatusChanged))
        connection.removeEventListener(.ioError, selector: #selector(onRtmpErrorIssued))
    }
    
    @objc private func onRtmpStatusChanged(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject,
            let code: String = data["code"] as? String else {
                return
        }
        
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            delegate?.rtmpLiveCasterConnectionSucceeded()
            stream.publish(streamKey, type: .live)
        case RTMPConnection.Code.connectFailed.rawValue:
            delegate?.rtmpLiveCaster(onConnection: .failed)
        case RTMPConnection.Code.connectClosed.rawValue:
            delegate?.rtmpLiveCasterConnectionClosed()
        default:
            break
        }
    }
    
    @objc private func onRtmpErrorIssued(_ notification: Notification) {
        let e = Event.from(notification)
        delegate?.rtmpLiveCaster(onConnection: .failedWith(code: e))
    }
}
