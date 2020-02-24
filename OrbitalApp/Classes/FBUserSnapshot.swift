//
//  ORUserCreateRequest.swift
//  orbitalApp
//
//  Created by Ryoichiro Oka on 12/15/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation

struct FBUserSnapshot : Codable {
    let id: String
    let name: String?
    let email: String?
    let profile_image_url: URL?
    let livecast_time_limit: Int
    let client: String?
}
