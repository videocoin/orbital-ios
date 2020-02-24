//
//  FirebaseUtils.swift
//  OrbitalApp
//
//  Created by Ryoichiro Oka on 12/28/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import Firebase
import PromiseKit

extension Auth {
    func signInPromise(with credential: AuthCredential) -> Promise<AuthDataResult> {
        return Promise<AuthDataResult> { seal in
            self.signIn(with: credential) { (auth, error) in
                if let error = error {
                    seal.reject(error)
                    return
                }
                
                seal.fulfill(auth!)
            }
        }
    }
}

extension DocumentReference {
    func getDocumentPromise() -> Promise<DocumentSnapshot> {
        return Promise<DocumentSnapshot> { seal in
            self.getDocument { (document, error) in
                if let error = error {
                    // You'll get an error "Missing or insufficient permissions"
                    // if your database's Rules are set to default:
                    // read/write permissions are denied for any docs.
                    seal.reject(error)
                    return
                }
                
                seal.fulfill(document!)
            }
        }
    }
    
    func setDataPromise(_ documentData: [String: Any], merge: Bool = false) -> Promise<Void> {
        return Promise<Void>{ seal in
            self.setData(documentData, merge: merge) { error in
                if let error = error {
                    seal.reject(error)
                    return
                }
                
                seal.fulfill(())
            }
        }
    }
}

extension CollectionReference {
    func getDocumentsPromise() -> Promise<QuerySnapshot> {
        return Promise<QuerySnapshot> { seal in
            self.getDocuments() { (query, error) in
                if let error = error {
                    seal.reject(error)
                    return
                }
                
                seal.fulfill(query!)
            }
        }
    }
}

extension RemoteConfig {
    func fetchPromise(with expirationDuration: TimeInterval) -> Promise<RemoteConfigFetchStatus> {
        Promise<RemoteConfigFetchStatus> { seal in
            self.fetch(withExpirationDuration: expirationDuration) { (status, error) in
                if let error = error {
                    seal.reject(error)
                    return
                }
                
                seal.fulfill(status)
            }
        }
    }
    
    func activatePromise() -> Promise<Void> {
        Promise<Void> { seal in
            self.activate() { error in
                if let error = error {
                    seal.reject(error)
                    return
                }
                
                seal.fulfill(())
            }
        }
    }
    
    func fetchAndActivatePromise() -> Promise<RemoteConfigFetchAndActivateStatus> {
        Promise<RemoteConfigFetchAndActivateStatus> { seal in
            self.fetchAndActivate { (status, error) in
                if let error = error {
                    seal.reject(error)
                    return
                }
                
                seal.fulfill(status)
            }
        }
    }
}

extension StorageReference {
    func putDataPromise(_ uploadData: Data, metadata: StorageMetadata?) -> Promise<StorageMetadata> {
        Promise<StorageMetadata> { seal in
            self.putData(uploadData, metadata: metadata) { metadata, error in
                if let error = error {
                    seal.reject(error)
                    return
                }
                
                seal.fulfill(metadata!)
            }
        }
    }
    
    func downloadUrlPromise() -> Promise<URL> {
        Promise<URL> { seal in
            self.downloadURL() { (url, error) in
                if let error = error {
                    seal.reject(error)
                    return
                }
                
                seal.fulfill(url!)
            }
        }
    }
}
