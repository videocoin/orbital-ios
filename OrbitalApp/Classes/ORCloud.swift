//
//  ORCloud.swift
//  orbitalApp
//
//  Created by Ryoichiro Oka on 12/15/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import Firebase
import GoogleSignIn
import PromiseKit
import VideoCoin

class ORCloud {
    static let shared = ORCloud()

    private let vcNetwork = VCStreamClient(
        host: "https://studio.snb.videocoin.network")
    
    private var auth: AuthDataResult?
    private var user: FBUserSnapshot?
    
    private init() {}
    
    var userName: String? { return user!.name }
    var userImageUrl: URL? { return user!.profile_image_url }
    var livecastTimeLimitSecs: Int { return FBRemoteConfig.shared.DEFAULT_LIVE_CAST_TIME_LIMIT_IN_SEC }
    
    func authenticate(_ auth: GIDAuthentication, _ profile: GIDProfileData) -> Promise<Void> {
        firstly {
            FBRemoteConfig.shared.updateSnapshot()
        }.then {
            FBDatabase.shared.authenticate(googleAuth: auth)
        }.get { databaseAuth in
            self.auth = databaseAuth
            self.user = self.makeUser(databaseAuth, profile)
            self.vcNetwork.accessToken = FBRemoteConfig.shared.API_KEY
            debugPrint("api key: \(self.vcNetwork.accessToken ?? "[empty]")")
        }.then { userExistsInDatabase in
            FBDatabase.shared.createUser(self.makeUser(self.auth!, profile))
        }.recover { error in
            switch error {
            case FBDatabaseError.userExists:
                debugPrint("user already exists")
            default:
                throw error
            }
        }
    }
    
    private func makeUser(_ auth: AuthDataResult, _ profile: GIDProfileData) -> FBUserSnapshot {
        FBUserSnapshot(
            id: auth.user.uid,
            name: auth.user.displayName!,
            email: auth.user.email!,
            profile_image_url: makeProfileImageUrl(profile),
            livecast_time_limit: FBRemoteConfig.shared.DEFAULT_LIVE_CAST_TIME_LIMIT_IN_SEC,
            client: "ios")
    }
    
    private func makeProfileImageUrl(_ profile: GIDProfileData) -> URL {
        profile.imageURL(withDimension: .init(256))
    }
    
    func fetchVideos() -> Promise<[FBVideoSnapshot]> {
        FBDatabase.shared.fetchVideos()
    }
    
    func openStreaming(title: String, cancelled: (() -> Bool)? = nil) -> Promise<VCStreamSnapshot> {
        firstly {
            self.vcNetwork.createStream(VCStreamCreateRequest(
                name: title,
                profile_id: FBRemoteConfig.shared.IOS_STREAM_PROFILE_ID))
        }.get { _ in
            debugPrint("created stream")
        }.then { streamSnapshot in
            self.vcNetwork.runStream(streamSnapshot.id)
        }.then { streamSnapshot in
            self.vcNetwork.pingUntilPrepared(
                streamSnapshot.id,
                count: 10,
                interval: .seconds(3),
                cancelled: cancelled)
        }
    }

    func startStreaming(_ id: String, image: Data, cancelled: (() -> Bool)? = nil) -> Promise<VCStreamSnapshot> {
        firstly {
            self.vcNetwork.pingUntilReady(
                id, count: 40,
                interval: .seconds(3),
                cancelled: cancelled)
        }.then { streamSnapshot in
            FBStorage.shared.uploadThumbnailImage(image).map { ($0, streamSnapshot) }
        }.then { (imageUrl, streamSnapshot) in
            self.uploadVideo(streamSnapshot, imageUrl).map { streamSnapshot }
        }
    }

    private func uploadVideo(_ stream: VCStreamSnapshot, _ imageUrl: URL) -> Promise<Void> {
        let video = FBVideoSnapshot(
            id: stream.id,
            title: stream.name,
            playback_url: stream.output_url,
            status: .LIVE,
            created_at: Int(NSDate().timeIntervalSince1970 * 1000),
            duration: 0,
            image_url: imageUrl,
            creator_img_url: self.user!.profile_image_url,
            creator_name: self.user!.name,
            client: "ios")
        
        return FBDatabase.shared.createVideo(video)
    }
    
    func stopStreaming(_ id: String) -> Promise<FBVideoSnapshot> {
        firstly {
            self.vcNetwork.stopStream(id)
        }.then { stream in
            FBDatabase.shared.endVideo(stream)
        }
    }
    
    func pingStream(_ id: String, cancelled: (() -> Bool)? = nil) -> Promise<VCStreamSnapshot> {
        firstly {
            self.vcNetwork.pingStream(id, cancelled: cancelled)
        }
    }
}
