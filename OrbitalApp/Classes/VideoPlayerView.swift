//
//  VideoPlayerView.swift
//  OrbitalApp
//
//  Created by Ryoichiro Oka on 1/25/20.
//  Copyright © 2020 Ryoichiro Oka. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class VideoPlayerView: UIView {
    override class var layerClass: AnyClass {
      return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
      return layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
      get {
        return playerLayer.player
      }

      set {
        playerLayer.player = newValue
      }
    }
}
