//
//  TimerTests.swift
//  OrbitalAppTests
//
//  Created by Ryoichiro Oka on 1/25/20.
//  Copyright © 2020 Ryoichiro Oka. All rights reserved.
//

import XCTest
@testable import OrbitalApp

class TimerTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLessThanOneMinute() {
        let (minutes, seconds) = LivecastTimer.formatTime(59)
        XCTAssertEqual(minutes, 0)
        XCTAssertEqual(seconds, 59)
    }
    
    func testOneMinuteSomeSeconds() {
        let (minutes, seconds) = LivecastTimer.formatTime(69)
        XCTAssertEqual(minutes, 1)
        XCTAssertEqual(seconds, 9)
    }
    
    func testSomeMinutesSomeSeconds() {
        let (minutes, seconds) = LivecastTimer.formatTime(129)
        XCTAssertEqual(minutes, 2)
        XCTAssertEqual(seconds, 9)
    }
}
