//
//  MainViewController.swift
//  orbitalApp
//
//  Created by Ryoichiro Oka on 12/9/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import PromiseKit
import GoogleSignIn

class MainViewController: UIViewController {
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var liveVideoStackView: UIStackView!
    @IBOutlet weak var endedVideoStackView: UIStackView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    private let segueViewVideo = "View Video"
    private let segueStartLiveCast = "Start Live Cast"
    private let segueUnwindToAuth = "On Logged Out"
    private let mainScrollPullHandler = UIRefreshControl()
    private var selectedVideo: FBVideoSnapshot?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch user profile image
        profileButton.kf.setImage(with: ORCloud.shared.userImageUrl, for: .normal)
        
        // Handle "pull to refresh"
        mainScrollPullHandler.addTarget(self, action: #selector(onMainScrollPulled), for: .valueChanged)
        mainScrollPullHandler.tintColor = UIColor(named: "Forefront Color")
        mainScrollView.refreshControl = mainScrollPullHandler
        
        // Fetch videos from the cloud when this view is opened
        fetchVideos().catch(onError(_:))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let screen = segue.destination as? ScreenViewController {
            screen.video = selectedVideo!
        }
    }
    
    @IBAction func onStartVideoingButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: segueStartLiveCast, sender: self)
    }
    
    @IBAction func onProfileButtonPressed(_ sender: Any) {
        let alert = UIAlertController(
            title: ORCloud.shared.userName,
            message: "",
            preferredStyle: .alert)

        alert.addAction(UIAlertAction(
            title: "OK",
            style: .cancel,
            handler: nil))

        alert.addAction(UIAlertAction(
            title: "Log Out",
            style: .destructive,
            handler: { _ in self.logOut() }))
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func unwindToMain(unwindSegue: UIStoryboardSegue) {
        fetchVideos().catch(onError(_:))
    }
    
    private func logOut() {
        GIDSignIn.sharedInstance().signOut()
        performSegue(withIdentifier: segueUnwindToAuth, sender: self)
    }
    
    @objc func onMainScrollPulled() {
        firstly {
            fetchVideos()
        }.done(on: DispatchQueue.main) {
            self.mainScrollPullHandler.endRefreshing()
        }.catch(self.onError(_:))
    }
    
    private func fetchVideos() -> Promise<Void> {
        firstly {
            ORCloud.shared.fetchVideos()
        }.done { videos in
            let liveVideos = videos.filter { $0.status == .LIVE }
            let endedVideos = videos.filter { $0.status == .ENDED }
            
            self.onVideosFetched(liveVideos, stackView: self.liveVideoStackView, nibName: "LargeVideoView")
            self.onVideosFetched(endedVideos, stackView: self.endedVideoStackView, nibName: "SmallVideoView")
        }
    }
    
    private func onError(_ error: Error) {
        //TODO impl
        debugPrint(error.localizedDescription)
    }
    
    private func onVideosFetched(_ videos: [FBVideoSnapshot], stackView: UIStackView, nibName: String) {
        let videos = videos.sorted { $0.created_at > $1.created_at }
        let views = stackView.arrangedSubviews.map { $0 as! VideoView }
        
        // handle removed videos
        let videosDictionary = videos.reduce(into: [:]) { $0[$1.id] = $1 }
        for view in views.filter({ videosDictionary[$0.video!.id] == nil }) {
            view.removeFromSuperview()
        }
        
        // handle added/updated videos
        let viewsDictionary = views.reduce(into: [:]) { $0[$1.video!.id] = $1 }
        for (i, video) in videos.enumerated() {
            if let view = viewsDictionary[video.id] {
                // handle updated videos
                view.update(content: video)
                view.update(layout: stackView)
                stackView.insertArrangedSubview(view, at: i)
            } else {
                // handle added videos
                let view = Bundle.main.loadView(VideoView.self, fromNib: nibName)!
                view.delegate = self
                view.update(content: video)
                view.update(layout: stackView)
                
                stackView.insertArrangedSubview(view, at: i)
            }
        }
    }
}

extension MainViewController: VideoViewDelegate {
    func videoView(selected video: FBVideoSnapshot) {
        selectedVideo = video
        performSegue(withIdentifier: segueViewVideo, sender: self)
    }
}
