//
//  VideoCoinViewController.swift
//  OrbitalApp
//
//  Created by Ryoichiro Oka on 1/14/20.
//  Copyright © 2020 Ryoichiro Oka. All rights reserved.
//

import Foundation
import UIKit

class VideoCoinViewController: UIViewController {
    @IBAction func onLearnMoreButtonPressed(_ sender: Any) {
        UIApplication.shared.open(
            URL(string: "https://www.videocoin.io/")!,
            options: [:],
            completionHandler: nil)
    }
}
