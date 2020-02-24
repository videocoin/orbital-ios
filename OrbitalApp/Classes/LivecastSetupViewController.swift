//
//  LivecastSetupViewController.swift
//  orbitalApp
//
//  Created by Ryoichiro Oka on 12/16/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import UIKit
import KeyboardLayoutGuide
import PromiseKit

class LivecastSetupViewController: UIViewController {
    @IBOutlet weak var mainLayout: UIView!
    @IBOutlet weak var titleText: UITextField!
    @IBOutlet weak var wordCountLabel: UILabel!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextButton: UIButton!
    
    private let model = LivecastTitleValidator()
    private let segueLivecast = "Let's Go"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.delegate = self
        titleText.delegate = self
        
        // make the bottom of the UI animate with the keyboard
        let keyboardBottomConstraint = mainLayout.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        bottomConstraint.isActive = false
        keyboardBottomConstraint.isActive = true
        
        model.updateTitle("")
        titleText.becomeFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Open Livecast page
        if let vc = segue.destination as? LivecastViewController {
            vc.streamTitle = model.title
        }
    }
    
    @IBAction func unwindToLivecastSetup(unwindSegue: UIStoryboardSegue) {
        
    }
}

extension LivecastSetupViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        return model.validateTitleInput(newTitle: newText)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if model.canStartStreaming() {
            performSegue(withIdentifier: "Let's Go", sender: nil)
        } else {
            //TODO notify
        }
        
        return true
    }
}

extension LivecastSetupViewController: LivecastTitleValidatorDelegate {
    func livecastTitleValidator(onTitleChanged newTitle: String) {
        wordCountLabel.text = model.subtitle
        
        let canGoNext = model.canStartStreaming()
        nextButton.isUserInteractionEnabled = canGoNext
        nextButton.backgroundColor = canGoNext
            ? UIColor(named: "Red 5")
            : UIColor(named: "Red 5 Inactive")
    }
}
