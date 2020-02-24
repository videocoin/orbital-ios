//
//  ORStream.swift
//  orbitalApp
//
//  Created by Ryoichiro Oka on 12/15/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation

struct FBVideoSnapshot : Codable {
    let id: String
    let title: String
    var playback_url: URL
    var status: FBVideoStatus
    let created_at: Int
    let duration: Float
    let image_url: URL?
    let creator_img_url: URL?
    let creator_name: String?
    let client: String?
    
    func makeEnded(playbackUrl: URL) -> FBVideoSnapshot {
        var other = self
        other.status = .ENDED
        other.playback_url = playbackUrl
        return other
    }
}
