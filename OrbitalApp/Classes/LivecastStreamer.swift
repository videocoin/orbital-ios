//
// Created by Ryoichiro Oka on 12/29/19.
// Copyright (c) 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import AVFoundation
import HaishinKit
import PromiseKit

protocol LivecastStreamerDelegate {
	func livecastStreamer(onStateUpdated state: LivecastStreamerState)
	func livecastStreamer(onError error: Error)
}

enum LivecastStreamerState {
	case idling
	case preparing
	case streaming
}

enum LivecastStreamerError : LocalizedError {
    case capturePermissionDenied
	case cancelledByUser
	case failedCapture
	case failedConnection
    
    var errorDescription: String? {
        switch self {
        case .capturePermissionDenied: return "Permission for video/audio capture denied by user"
        case .cancelledByUser: return "Live cast cancelled by user"
        case .failedCapture: return "Failed to capture video or audio"
        case .failedConnection: return "Failed to connect to the cloud"
        }
    }
}

class LivecastStreamer {
	private let caster: RtmpLiveCaster
    
    private var view: GLHKView?
	private var startError: LivecastStreamerError?
    
    private(set) var state: LivecastStreamerState?
	private(set) var castingFrontCamera: Bool = false
    private var activeStreamId: String?

	var delegate: LivecastStreamerDelegate?
    var streamTitle: String! {
        didSet {
            debugPrint("LivecastStreamer.streamTitle = \(streamTitle ?? "[nil]")")
        }
    }

	init() {
		caster = RtmpLiveCaster()
		caster.delegate = self
	}
	
	func initialize() -> Promise<Void> {
        firstly {
            self.requestCaptureAuths()
        }.map { permissionGranted in
            if !permissionGranted {
                throw LivecastStreamerError.capturePermissionDenied
            }
            
            try self.caster.configure(config: RtmpLiveCasterConfig.defaultConfig)
            self.caster.attachCamera(position: .back)
            
            self.state = nil
            self.updateState(.idling)
        }
	}
    
    private func requestCaptureAuths() -> Promise<Bool> {
        return Promise<Bool> { seal in
            caster.requestCaptureAuths(for: { permissionGranted in
                seal.fulfill(permissionGranted)
            })
        }
    }

	func attachView(view: GLHKView) {
        self.view = view
        self.caster.attachStream(view: view)
	}
	
	func switchCamera(_ to: Bool? = nil) {
		castingFrontCamera = to ?? !castingFrontCamera
		caster.attachCamera(position: castingFrontCamera ? .front : .back)
	}
    
	func startStreaming() {
		updateState(.preparing)
		startError = nil
        activeStreamId = nil

		firstly {
            ORCloud.shared.openStreaming(
                title: self.streamTitle,
                cancelled: { self.startError != nil })
		}.get { streamSnapshot in
            self.activeStreamId = streamSnapshot.id
			try self.throwIfFailedStartingStreaming()
            self.caster.connect(streamSnapshot.rtmp_url.absoluteString)
		}.then { streamSnapshot in
			ORCloud.shared.startStreaming(
                streamSnapshot.id,
                image: self.captureScreen(),
                cancelled: { self.startError != nil })
		}.get { streamSnapshot in
			try self.throwIfFailedStartingStreaming()
			self.updateState(.streaming)
        }.catch { error in
            self.endStreaming().catch { error in
                self.delegate?.livecastStreamer(onError: error)
            }
            
            self.updateState(.idling)
            
            switch error {
            case LivecastStreamerError.cancelledByUser, // user action
                 LivecastStreamerError.failedCapture, // already notified
                 LivecastStreamerError.failedConnection: // already notified
                break
            default:
                self.notifyError(error)
            }
		}
	}

	private func throwIfFailedStartingStreaming() throws {
		if let error = startError {
			throw error
		}
	}

	private func captureScreen() -> Data {
        guard let view = self.view else {
            debugPrint("Using the placeholder image as a thumbnail because view is not set")
            return UIImage(named: "photo_1920x1080.jpg")!.jpegData(compressionQuality: 0.8)!
        }
        
        return view.capture()!.jpegData(compressionQuality: 0.8)!
	}

	func cancelStreaming() {
		self.startError = .cancelledByUser
		self.updateState(.idling)
	}

	func endStreaming() -> Promise<FBVideoSnapshot?> {
        self.startError = .cancelledByUser
		caster.disconnect()
        
        if let activeStreamId = activeStreamId {
            return firstly {
                ORCloud.shared.stopStreaming(activeStreamId)
            }.map { video -> FBVideoSnapshot? in
                return video
            }
        } else {
            return Promise<FBVideoSnapshot?>.value(nil)
        }
	}

	private func updateState(_ state: LivecastStreamerState) {
        if state != self.state {
            debugPrint("LivecastStreamer.updateState(\(state))")
			self.state = state
			delegate?.livecastStreamer(onStateUpdated: state)
		}
	}

	private func notifyError(_ error: Error) {
		delegate?.livecastStreamer(onError: error)
	}
}

extension LivecastStreamer: RtmpLiveCasterDelegate {
    /// called when the screen capture failed
    func rtmpLiveCaster(onCapture error: Error) {
        debugPrint("onCapture ", error)

        // handle when this error occurred during startup
        startError = .failedCapture

        notifyError(error)

        caster.disconnect()
        updateState(.idling)
    }

    // called when the stream connection failed
    func rtmpLiveCaster(onConnection error: RtmpLiveCasterError) {
        debugPrint("onConnection ", error)

        // handle when this error occurred during startup
        startError = .failedConnection

        notifyError(error)

        caster.disconnect()
        updateState(.idling)
    }

    func rtmpLiveCasterConnectionSucceeded() {
        debugPrint("onConnectionSucceeded")
    }

    func rtmpLiveCasterConnectionClosed() {
        debugPrint("onConnectionClosed")
        updateState(.idling)
    }
}
