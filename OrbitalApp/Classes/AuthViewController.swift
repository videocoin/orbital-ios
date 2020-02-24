//
//  LandingViewController.swift
//  orbitalApp
//
//  Created by Ryoichiro Oka on 12/2/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import UIKit
import GoogleSignIn
import PromiseKit

class AuthViewController: UIViewController {
    
    @IBOutlet weak var googleSigninButton: UIButton!
    @IBOutlet weak var videocoinButton: UIButton!
    @IBOutlet weak var loadingView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide Google button until we know the user isn't signed in
        googleSigninButton.isHidden = true
        
        // GoogleSignIn https://firebase.google.com/docs/auth/ios/google-signin
        GIDSignIn.sharedInstance().delegate = self // extension below
        GIDSignIn.sharedInstance().presentingViewController = self
        
        // Allow fetching user profile images
        GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
        
        // Check if user is already signed in
        if GIDSignIn.sharedInstance().hasPreviousSignIn() {
            debugPrint("GoogleSignIn: Refresh token exists. Signing in")
            
            // Invoke the whole sign-in chain using the refresh token
            // (eventually pushing the main scene)
            GIDSignIn.sharedInstance().restorePreviousSignIn()
            onAuthStateChanged(signingIn: true)
        } else {
            onAuthStateChanged(signingIn: false)
        }
    }
    
    @IBAction func onGoogleSignInButtonPressed(_ sender: Any) {
        debugPrint("onGoogleSignInButtonPressed()")
        GIDSignIn.sharedInstance().signIn()
        onAuthStateChanged(signingIn: true)
    }
    
    @IBAction func unwindToAuth(unwindSegue: UIStoryboardSegue) {
        GIDSignIn.sharedInstance()?.signOut()
        onAuthStateChanged(signingIn: false)
    }
    
    // Enter the main scene. Invoked when the user is authenticated with the database
    private func onAuthSuccess() {
        performSegue(withIdentifier: "Signed In", sender: self)
        
        onAuthStateChanged(signingIn: true)
    }
    
    // Show user an error message
    private func onAuthFailed(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: { _ in
                self.onAuthStateChanged(signingIn: false)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func onAuthStateChanged(signingIn: Bool) {
        googleSigninButton.isHidden = signingIn
        loadingView.isHidden = !signingIn
    }
}

extension AuthViewController: GIDSignInDelegate {
    
    // Invoked when Google button is pressed (or found a refresh token)
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        debugPrint("GIDSignInDelegate.sign()")
        
        if let error = error {
            debugPrint("GoogleSignIn: sign in error: \(error)")
            self.onAuthFailed(
                title: "Failed signing in to Google",
                message: error.localizedDescription)
            return
        }
        
        firstly {
            ORCloud.shared.authenticate(user.authentication!, signIn.currentUser.profile)
        }.done {
            debugPrint("Authentication success")
            self.onAuthSuccess()
        }.catch { error in
            debugPrint("Authentication failed: \(type(of: error)) \(error)")
            self.onAuthFailed(
                title: "Authentication failed",
                message: error.localizedDescription)
        }
    }
}
