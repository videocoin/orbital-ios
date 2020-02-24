//
//  ScreenViewController.swift
//  orbitalApp
//
//  Created by Ryoichiro Oka on 12/15/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import AVFoundation

class ScreenViewController : UIViewController {
    @IBOutlet weak var playbackView: VideoPlayerView!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var creatorPicView: UIImageView!
    @IBOutlet weak var creatorNameView: UILabel!
    @IBOutlet weak var streamNameView: UILabel!
    @IBOutlet weak var streamStateView: UILabel!
    @IBOutlet weak var replayFadeView: UIView!
    @IBOutlet weak var replayButtonView: UIStackView!
    
    var video: FBVideoSnapshot!
    private var player: AVPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // stop player
        player?.pause()
        player = nil
        playbackView.player = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playVideo()
    }
    
    private func playVideo() {
        debugPrint("ScreenViewController video URL: \(video.playback_url)")
        
        replayFadeView.isHidden = true
        replayButtonView.isHidden = true
        
        player = AVPlayer(url: video.playback_url)
        player!.addObserver(self, forKeyPath: "status", options: [], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onFinishedPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        playbackView.player = player
        player!.play()
        
        streamNameView.text = video.title
        streamStateView.isHidden = video.status != .LIVE
        thumbnailView.kf.setImage(with: video.image_url)
        creatorNameView.text = video.creator_name
        creatorPicView.kf.setImage(with: video.creator_img_url)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let player = player,
              let keyPath = keyPath,
              keyPath == "status" else {
            return
        }
        
        switch player.status {
        case .unknown:
            return
        case .readyToPlay:
            thumbnailView.isHidden = true
        case .failed:
            dismissForError()
        @unknown default:
            return
        }
    }
    
    @objc func onFinishedPlaying(_ note: Notification) {
        debugPrint("finished playing")
        
        replayFadeView.isHidden = false
        replayButtonView.isHidden = false
    }
    
    @IBAction func onReplayButtonPressed(_ sender: Any) {
        playVideo()
    }
    
    private func dismissForError() {
        let alert = UIAlertController(
            title: "Invalid video request",
            message: "Cannot play this video",
            preferredStyle: .alert)

        alert.addAction(UIAlertAction(
            title: "Back",
            style: .default,
            handler: { _ in self.dismiss(animated: true) }))

        present(alert, animated: true, completion: nil)
    }
}
