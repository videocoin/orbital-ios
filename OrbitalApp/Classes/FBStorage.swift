//
// Created by Ryoichiro Oka on 12/29/19.
// Copyright (c) 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import Firebase
import PromiseKit

class FBStorage {
	static let shared = FBStorage()

	private init() {}

	func uploadThumbnailImage(_ image: Data) -> Promise<URL> {
        let ref = Storage.storage().reference().child(self.makeThumbnailImagePath())
        
        return firstly {
            ref.putDataPromise(image, metadata: nil)
        }.then { _ in
            ref.downloadUrlPromise()
        }
	}
    
    private func makeThumbnailImagePath() -> String {
        "video_thumbnails/\(UUID().uuidString).jpg"
    }
}
