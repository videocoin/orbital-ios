//
//  ViewController.swift
//  RtmpDebug
//
//  Created by Ryoichiro Oka on 12/1/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import UIKit
import HaishinKit
import AVFoundation

class ViewController: UIViewController, RtmpLiveCasterDelegate {
    @IBOutlet weak var lfView: GLHKView!
    
    let destination = "rtmp://169.254.37.114/live"
    let streamKey = "stream"
    
    private let caster = RtmpLiveCaster()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        caster.delegate = self
        try! caster.configure(config: RtmpLiveCasterConfig.defaultConfig)
        caster.attachCamera(position: .back)
        caster.attachStream(view: lfView)
        caster.connect(destination: destination, streamKey: streamKey)
        
        debugPrint("videoDidLoad()")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        caster.disconnect()
    }
    
    func rtmpLiveCaster(onCapture error: Error) {
        debugPrint("onCapture ", error)
    }
    
    func rtmpLiveCaster(onConnection error: RtmpLiveCasterError) {
        debugPrint("onConnectionFailed")
    }
    
    func rtmpLiveCasterConnectionSucceeded() {
        debugPrint("onConnectionSucceeded")
    }
    
    func rtmpLiveCasterConnectionClosed() {
        debugPrint("onConnectionClosed")
    }
}
