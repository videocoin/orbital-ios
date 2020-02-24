//
//  OrbitalAppTests.swift
//  OrbitalAppTests
//
//  Created by Ryoichiro Oka on 12/27/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import XCTest
import PromiseKit
import GoogleSignIn
@testable import OrbitalApp
import HaishinKit

class ServerTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_RemoteConfig() {
        let e = expectation(description: "timeout")
        
        firstly {
            FBRemoteConfig.shared.updateSnapshot()
        }.done { () in
            debugPrint("remote config livecast time limit: \(FBRemoteConfig.shared.DEFAULT_LIVE_CAST_TIME_LIMIT_IN_SEC ?? 0)")
            debugPrint("remote config stream profile id: \(FBRemoteConfig.shared.ANDROID_STREAM_PROFILE_ID ?? "")")
            debugPrint("remote config api key: \(FBRemoteConfig.shared.API_KEY ?? "")")
            
            XCTAssertNotEqual(FBRemoteConfig.shared.DEFAULT_LIVE_CAST_TIME_LIMIT_IN_SEC, 0)
            XCTAssertNotEqual(FBRemoteConfig.shared.ANDROID_STREAM_PROFILE_ID, "")
            XCTAssertNotEqual(FBRemoteConfig.shared.API_KEY, "")
            e.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_VideoList() {
        firstly {
            ORCloud.shared.fetchVideos()
        }.done { videos in
            XCTAssertNotEqual(videos.count, 0)
        }.catch { error in
            XCTFail(error.localizedDescription)
        }
    }
    
    // run this test on a real device
    func test_Streaming() {
        let e = expectation(description: "timeout")
        
        if GIDSignIn.sharedInstance().hasPreviousSignIn() {
            GIDSignIn.sharedInstance().restorePreviousSignIn()
        } else {
            XCTFail("not signed in")
        }
        
        let caster = RtmpLiveCaster()
        caster.delegate = self
        try! caster.configure(config: RtmpLiveCasterConfig.defaultConfig)
        caster.attachCamera(position: .front)
        
        firstly {
            after(.seconds(5))
        }.then { _ in
            ORCloud.shared.authenticate(
                GIDSignIn.sharedInstance().currentUser.authentication,
                GIDSignIn.sharedInstance().currentUser.profile)
        }.then { _ in
            ORCloud.shared.openStreaming(title: "iOS Integration Test")
        }.get { stream in
            XCTAssertEqual(stream.status, VCStreamStatus.STREAM_STATUS_PREPARED)
            caster.connect(stream.rtmp_url.absoluteString)
        }.map { stream in
            let thumbnailImage = UIImage(named: "photo_1920x1080.jpg")
            let thumbnailData = thumbnailImage!.jpegData(compressionQuality: 0.8)!
            return (stream.id, thumbnailData)
        }.then { (streamId, thumbnail) in
            ORCloud.shared.startStreaming(streamId, image: thumbnail)
        }.get { stream in
            XCTAssertEqual(stream.status, VCStreamStatus.STREAM_STATUS_READY)
        }.then { stream in
            FBDatabase.shared.fetchVideo(stream.id)
        }.get { video in
            XCTAssertEqual(video.status, FBVideoStatus.LIVE)
        }.then { video in
            ORCloud.shared.stopStreaming(video.id).map { _ in video.id }
        }.then { videoId in
            ORCloud.shared.pingStream(videoId)
        }.get { stream in
            XCTAssertEqual(stream.status, VCStreamStatus.STREAM_STATUS_COMPLETED)
        }.then { stream in
            FBDatabase.shared.fetchVideo(stream.id)
        }.done { video in
            XCTAssertEqual(video.status, FBVideoStatus.ENDED)
            e.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }
        
        waitForExpectations(timeout: 180, handler: nil)
    }
}

extension ServerTests: RtmpLiveCasterDelegate {
    func rtmpLiveCaster(onCapture error: Error) {
        debugPrint("onCapture ", error)
    }
    
    func rtmpLiveCaster(onConnection error: RtmpLiveCasterError) {
        debugPrint("onConnectionFailed: \(error.localizedDescription)")
    }
    
    func rtmpLiveCasterConnectionSucceeded() {
        debugPrint("onConnectionSucceeded")
    }
    
    func rtmpLiveCasterConnectionClosed() {
        debugPrint("onConnectionClosed")
    }
}
