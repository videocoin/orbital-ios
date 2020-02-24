//
//  LivecastEndedViewController.swift
//  OrbitalApp
//
//  Created by Ryoichiro Oka on 1/2/20.
//  Copyright © 2020 Ryoichiro Oka. All rights reserved.
//

import Foundation
import UIKit

class LivecastEndedViewController: UIViewController {
    @IBOutlet weak var viewEndedCastButton: UIButtonExt!
    private var video: FBVideoSnapshot!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setViewEndedCastButton(interactable: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let screenView = segue.destination as? ScreenViewController {
            screenView.video = video
        }
    }
    
    func set(video: FBVideoSnapshot) {
        self.video = video
        setViewEndedCastButton(interactable: true)
    }
    
    private func setViewEndedCastButton(interactable: Bool) {
        viewEndedCastButton.isUserInteractionEnabled = interactable
        viewEndedCastButton.backgroundColor = interactable
            ? UIColor(named: "Red 5")
            : UIColor(named: "Red 5 Inactive")
    }
}
