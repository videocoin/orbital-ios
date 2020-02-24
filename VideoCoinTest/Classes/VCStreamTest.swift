//
//  CloudSourceTest.swift
//  orbitalTests
//
//  Created by Ryoichiro Oka on 11/18/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import XCTest
import Alamofire
import PromiseKit
import SwiftyJSON
@testable import VideoCoin
import HaishinKit

// HOW TO USE THIS TEST
// - Run the entire test (not one by one)
// - Run the test on a real device (for reading the camera input)
class VCStreamTest: XCTestCase, RtmpLiveCasterDelegate {
    let host = "https://studio.videocoin.network"
    
    // Insert your own access token here
    let accessToken: String = <# ACCESS TOKEN #>
    
    var cloudSource: VCStreamClient!
    
    static var profileId: String!
    static var streamId: String!
    static var streamSnapshot: VCStreamSnapshot?

    override func setUp() {
        // This is the setUp() class method.
        // It is called before the first test method begins.
        // Set up any overall initial state here.
        
        self.cloudSource = VCStreamClient(host: host)
        self.cloudSource.accessToken = accessToken
    }
    
    override func tearDown() {
        // Put teardown code here.
        // This method is called after the invocation of each test method in the class.
    }
    
    func test010_Profiles() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let e = expectation(description: "timeout")
        
        self.cloudSource.fetchStreamProfiles().done { streamProfiles in
            XCTAssertNotEqual(0, streamProfiles.count, "stream profile list must contain at least one item")
            
            for streamProfile in streamProfiles {
                debugPrint("stream profile: \(streamProfile.id) \(streamProfile.name) \(streamProfile.description)")
            }
            
            VCStreamTest.profileId = streamProfiles[0].id
            debugPrint("saving profile id: \(VCStreamTest.profileId ?? "[nil]")")
            
            e.fulfill()
        }.catch { error in
            XCTFail("\(error)")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test020_CreateStream() {
        let e = expectation(description: "timeout")
        
        let create = VCStreamCreateRequest(
            name: UUID.init().uuidString,
            profile_id: VCStreamTest.profileId!)
        
        debugPrint("creating stream: name: \(create.name), profile_id: \(create.profile_id)")
        
        self.cloudSource.createStream(create).done { streamEntity -> Void in
            VCStreamTest.streamId = streamEntity.id
            debugPrint("saving stream id: \(VCStreamTest.streamId!)")
            e.fulfill()
        }.catch { error -> Void in
            XCTFail("\(error)")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test030_RunStream() {
        let e = expectation(description: "timeout")
        
        let streamId = VCStreamTest.streamId!
        debugPrint("running stream id: \(streamId)")
        
        self.cloudSource.runStream(streamId).done { streamEntity -> Void in
            e.fulfill()
        }.catch { error -> Void in
            XCTFail("\(error)")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test040_PingStream() {
        let e = expectation(description: "timeout")
        
        let streamId = VCStreamTest.streamId!

        firstly {
            self.cloudSource.pingUntilPrepared(streamId, count: 5, interval: .seconds(3))
        }.done { stream -> Void in
            XCTAssertEqual(VCStreamStatus.STREAM_STATUS_PREPARED, stream.status)
            VCStreamTest.streamSnapshot = stream
            e.fulfill()
        }.catch { error -> Void in
            XCTFail("\(error)")
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    func test050_InjectStream() throws {
        let e = expectation(description: "timeout")

        let caster = RtmpLiveCaster()
        caster.delegate = self
        try caster.configure(config: RtmpLiveCasterConfig.defaultConfig)
        caster.attachCamera(position: .front)
        caster.connect(VCStreamTest.streamSnapshot!.rtmp_url.absoluteString)
        debugPrint("RtmpLiveCaster.connect()")
        
        let streamId = VCStreamTest.streamId!

        firstly {
            self.cloudSource.pingUntilReady(streamId, count: 40, interval: .seconds(3))
        }.done { stream -> Void in
            XCTAssertEqual(VCStreamStatus.STREAM_STATUS_READY, stream.status)
            debugPrint("stream successfully aired")
            e.fulfill()
        }.catch { error -> Void in
            XCTFail("\(error)")
        }
        
        waitForExpectations(timeout: 120, handler: nil)
    }
    
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
    
    func test060_StopStream() {
        let e = expectation(description: "timeout")
        
        let streamId = VCStreamTest.streamId!
        let wait = VCStreamTest.streamId == nil ? 0 : 5
        debugPrint("waiting before stop...")
        after(.seconds(wait)).then { () in
            self.cloudSource.stopStream(streamId)
        }.done{ stream -> Void in
            debugPrint(stream.status)
            XCTAssertEqual(stream.status, VCStreamStatus.STREAM_STATUS_COMPLETED)
            
            e.fulfill()
        }.catch { error -> Void in
            XCTFail("\(error)")
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}

