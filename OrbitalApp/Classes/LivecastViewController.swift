//
//  LivecastViewController.swift
//  orbitalApp
//
//  Created by Ryoichiro Oka on 12/16/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import HaishinKit
import PromiseKit

class LivecastViewController: UIViewController {
	@IBOutlet weak var streamView: GLHKView!
	@IBOutlet weak var overlayView: UIView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var preparingView: UIView!
    @IBOutlet weak var backButton: UIButton!
	@IBOutlet weak var timerLabel: UILabel!
	@IBOutlet weak var goLiveButton: UIButton!
	@IBOutlet weak var cancelButton: UIButton!
	@IBOutlet weak var endLiveButton: UIButton!
	@IBOutlet weak var cameraSwitchButton: UIButton!

    private let timer = LivecastTimer()
    private var model: LivecastStreamer!

    // set from the setup view controller
    var streamTitle: String!

	override func viewDidLoad() {
		super.viewDidLoad()

        model = LivecastStreamer()
        model.delegate = self
        
        firstly {
            self.model.initialize()
        }.done {
            self.model.attachView(view: self.streamView)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.onAppMovedToBackground),
                name: UIApplication.willResignActiveNotification,
                object: nil)
            
            self.timer.delegate = self
        }.catch { error in
            let alert = UIAlertController(
                title: "Faield initializing the livecast",
                message: error.localizedDescription,
                preferredStyle: .alert)

            alert.addAction(UIAlertAction(
                title: "Back",
                style: .default,
                handler: { _ in self.exit() }))

            self.present(alert, animated: true, completion: nil)
        }
	}
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        model.endStreaming().catch(onError(error:))
        timer.stopCounting()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let endedView = segue.destination as? LivecastEndedViewController {
            firstly {
                self.model.endStreaming()
            }.done { video in
                endedView.set(video: video!)
            }.catch { error in
                self.onError(error: error)
            }
        }
    }
    
    @IBAction func onGoLiveButtonPressed(_ sender: Any) {
        model.streamTitle = streamTitle
        model.startStreaming()
    }
    
    @IBAction func onCancelButtonPressed(_ sender: Any) {
        model.cancelStreaming()
    }
    
    @IBAction func onEndButtonPressed(_ sender: Any) {
        let alert = UIAlertController(
            title: "End Live Cast?",
            message: "This will end your Live Cast and return you to the home screen.",
            preferredStyle: .alert)

        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil))

        alert.addAction(UIAlertAction(
            title: "End",
            style: .destructive,
            handler: { _ in self.endLiveStreaming() }))

        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onCameraSwitchButtonPressed(_ sender: Any) {
        model.switchCamera()
    }
    
    // end the live streaming and navigate to the "ended" page
    private func endLiveStreaming() {
        model.endStreaming().catch(onError(error:))
        performSegue(withIdentifier: "On Ended", sender: self)
    }
    
    @objc private func onAppMovedToBackground() {
        switch model.state ?? .idling {
        case .idling: return
        case .preparing: model.cancelStreaming()
        case .streaming: model.endStreaming().catch(onError(error:))
        }
        
        let alert = UIAlertController(
            title: "Streaming has been terminated",
            message: "The app was paused.",
            preferredStyle: .alert)

        alert.addAction(UIAlertAction(
            title: "Back",
            style: .default,
            handler: { _ in self.exit() }))

        present(alert, animated: true, completion: nil)
    }
    
    private func exit() {
        performSegue(withIdentifier: "unwindToLivecastSetup", sender: self)
    }
    
    private func onError(error: Error) {
        debugPrint("\(type(of: error)): \(error.localizedDescription)")
        
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert)

        alert.addAction(UIAlertAction(
            title: "Ok",
            style: .default,
            handler: nil))

        present(alert, animated: true, completion: nil)
    }
}

extension LivecastViewController: LivecastStreamerDelegate {
	func livecastStreamer(onStateUpdated state: LivecastStreamerState) {
		DispatchQueue.main.async { [weak self] () -> Void in
			guard let self = self else {
				return
			}
            
            let state = self.model.state ?? LivecastStreamerState.idling
            
            debugPrint("LivecastViewController state: \(state)")

            // state title text
            switch state {
			case .idling: self.titleLabel.text = "Go Live"
			case .preparing: self.titleLabel.text = "Going Live"
			case .streaming: self.titleLabel.text = "Now Live"
			}

			self.preparingView.isHidden = state != .preparing
			self.backButton.isHidden = state != .idling
			self.timerLabel.isHidden = state != .streaming
			self.goLiveButton.isHidden = state != .idling
			self.cancelButton.isHidden = state != .preparing
			self.endLiveButton.isHidden = state != .streaming
			self.cameraSwitchButton.isHidden = state != .streaming
            
            if state == .streaming {
                let timelimitSecs = ORCloud.shared.livecastTimeLimitSecs
                self.timer.startCounting(timelimitSecs: Double(timelimitSecs))
            }
		}
	}
    
	func livecastStreamer(onError error: Error) {
        onError(error: error)
	}
}

extension LivecastViewController: LivecastTimerDelegate {
    func livecastTimerTimeChanged(minutes: Int, seconds: Int) {
        timerLabel.text = "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    func livecastTimerTimeLimitReached() {
        let alert = UIAlertController(
            title: "Reached the time limit.",
            message: "Ending this live cast.",
            preferredStyle: .alert)

        alert.addAction(UIAlertAction(
            title: "Ok",
            style: .default,
            handler: { _ in self.endLiveStreaming() }))

        present(alert, animated: true, completion: nil)
    }
}
