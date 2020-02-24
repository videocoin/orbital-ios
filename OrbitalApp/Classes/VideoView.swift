//
//  LargeVideoView.swift
//  OrbitalApp
//
//  Created by Ryoichiro Oka on 12/31/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import Kingfisher

protocol VideoViewDelegate {
    func videoView(selected video: FBVideoSnapshot)
}

// Heh why did I name this "Video View"... should be "Video Thumbnail View"
class VideoView: UIView {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var creatorImageView: UIImageView!
    @IBOutlet weak var creatorNameLabel: UILabel!
    @IBOutlet weak var videoTitleLabel: UILabel!
    
    var delegate: VideoViewDelegate?
    private(set) var video: FBVideoSnapshot?
    
    func update(content video: FBVideoSnapshot) {
        self.video = video
        
        creatorNameLabel.text = video.creator_name
        videoTitleLabel.text = video.title
        
        thumbnailImageView.kf.setImage(with: video.image_url)
        creatorImageView.kf.setImage(with: video.creator_img_url)
    }
    
    func update(layout stackView: UIStackView) {
        switch stackView.axis {
        case .horizontal:
            NSLayoutConstraint.activate([widthAnchor.constraint(equalToConstant: frame.width)])
        case .vertical:
            NSLayoutConstraint.activate([heightAnchor.constraint(equalToConstant: frame.height)])
        default:
            debugPrint("unknown axis: \(stackView.axis)")
        }
    }
    
    @IBAction func onSelectButtonPressed(_ sender: Any) {
        delegate?.videoView(selected: video!)
    }
}
