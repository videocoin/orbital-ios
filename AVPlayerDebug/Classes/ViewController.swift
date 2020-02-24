//
//  ViewController.swift
//  AVPlayerDebug
//
//  Created by Ryoichiro Oka on 1/27/20.
//  Copyright © 2020 Ryoichiro Oka. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class ViewController: AVPlayerViewController {
    let url = "http://127.0.0.1/monkey/index.m3u8"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player = AVPlayer(url: URL(string: url)!)
    }
}
