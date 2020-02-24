//
//  LivecastTimer.swift
//  OrbitalApp
//
//  Created by Ryoichiro Oka on 1/18/20.
//  Copyright © 2020 Ryoichiro Oka. All rights reserved.
//

import Foundation

protocol LivecastTimerDelegate {
    func livecastTimerTimeChanged(minutes: Int, seconds: Int)
    func livecastTimerTimeLimitReached()
}

class LivecastTimer: NSObject {
    var delegate: LivecastTimerDelegate?
    var timer: Timer?
    var startTime: Date!
    var timelimit: Double!
    
    func startCounting(timelimitSecs: Double) {
        timelimit = timelimitSecs
        startTime = .init(timeIntervalSinceNow: 0)
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(onTimer),
            userInfo: nil,
            repeats: true)
        onTimer() // update clock now too
    }
    
    func stopCounting() {
        timer?.invalidate()
    }
    
    @objc func onTimer() {
        let nowTime = Date.init(timeIntervalSinceNow: 0)
        let pastTime = nowTime.timeIntervalSince(startTime)
        let remainingTime = timelimit - pastTime
        
        if remainingTime > 0 {
            let (minutes, seconds) = LivecastTimer.formatTime(remainingTime)
            delegate?.livecastTimerTimeChanged(minutes: minutes, seconds: seconds)
        } else {
            timer!.invalidate()
            delegate?.livecastTimerTimeChanged(minutes: 0, seconds: 0)
            delegate?.livecastTimerTimeLimitReached()
        }
    }
    
    class func formatTime(_ time: Double) -> (Int, Int) {
        let minutes = Int(time / 60)
        let seconds = Int(time.truncatingRemainder(dividingBy: 60))
        return (minutes, seconds)
    }
}
