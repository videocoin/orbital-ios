//
//  ORDatabase.swift
//  orbitalApp
//
//  Created by Ryoichiro Oka on 12/15/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import Firebase
import GoogleSignIn
import PromiseKit
import SwiftyJSON

enum FBDatabaseError: LocalizedError {
    case userExists
    case videoExists
    case videoNotExists
    
    var errorDescription: String? {
        switch self {
        case .userExists: return "User exists in the database"
        case .videoExists: return "Video exists in the database"
        case .videoNotExists: return "Video was not found in the database"
        }
    }
}

class FBDatabase {
    // singleton because Firestore is singleton too :(
    static let shared = FBDatabase()
    
    private init() {}
    
    private func userDocument(_ id: String) -> DocumentReference {
        Firestore.firestore().collection("users").document(id)
    }
    
    private func videoCollection() -> CollectionReference {
        Firestore.firestore().collection("videos")
    }
    
    private func videoDocument(_ id:  String) -> DocumentReference {
        videoCollection().document(id)
    }
    
    func authenticate(googleAuth: GIDAuthentication) -> Promise<AuthDataResult> {
        let credential = GoogleAuthProvider.credential(
            withIDToken: googleAuth.idToken,
            accessToken: googleAuth.accessToken)
        
        return Auth.auth().signInPromise(with: credential)
    }
    
    func existsUser(_ id: String) -> Promise<Bool> {
        userDocument(id).getDocumentPromise().map { $0.exists }
    }
    
    func createUser(_ user: FBUserSnapshot) -> Promise<Void> {
        firstly {
            self.existsUser(user.id)
        }.get { userExists in
            if userExists {
                throw FBDatabaseError.userExists
            }
        }.then { _ in
            self.userDocument(user.id).setDataPromise(try user.asDictionary())
        }
    }
    
    func fetchVideos() -> Promise<[FBVideoSnapshot]> {
        videoCollection().getDocumentsPromise().map { query in
            var streams = [FBVideoSnapshot]()
            
            for document in query.documents {
                let stream = try document.data().decode(FBVideoSnapshot.self)
                streams.append(stream)
            }
            
            return streams
        }
    }
    
    func existsVideo(_ id: String) -> Promise<Bool> {
        videoDocument(id).getDocumentPromise().map { $0.exists }
    }
    
    func createVideo(_ entry: FBVideoSnapshot) -> Promise<Void> {
        firstly {
            self.existsVideo(entry.id)
        }.get { videoExists in
            if videoExists {
                throw FBDatabaseError.videoExists
            }
        }.then { _ in
            self.videoDocument(entry.id).setDataPromise(try entry.asDictionary())
        }
    }
    
    func fetchVideo(_ id: String) -> Promise<FBVideoSnapshot> {
        firstly {
            self.videoDocument(id).getDocumentPromise()
        }.get { videoDoc in
            if !videoDoc.exists {
                throw FBDatabaseError.videoNotExists
            }
        }.map { videoDoc in
            try videoDoc.data()!.decode(FBVideoSnapshot.self)
        }
    }
    
    func endVideo(_ stream: VCStreamSnapshot) -> Promise<FBVideoSnapshot> {
        firstly {
            self.videoDocument(stream.id).getDocumentPromise()
        }.get { videoDoc in
            if !videoDoc.exists {
                throw FBDatabaseError.videoNotExists
            }
        }.map { videoDoc in
            let video = try videoDoc.data()!.decode(FBVideoSnapshot.self)
            return video.makeEnded(playbackUrl: stream.output_url)
        }.then { endedVideo in
            self.videoDocument(stream.id)
                .setDataPromise(try endedVideo.asDictionary(), merge: true)
                .map { endedVideo }
        }
    }
}
