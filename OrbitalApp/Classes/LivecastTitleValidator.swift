//
//  LivecastTitleValidator.swift
//  OrbitalApp
//
//  Created by Ryoichiro Oka on 12/30/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation

protocol LivecastTitleValidatorDelegate {
    func livecastTitleValidator(onTitleChanged newTitle: String)
}

class LivecastTitleValidator {
    private let minWordCount = 6
    private let maxWordCount = 20
    
    var delegate: LivecastTitleValidatorDelegate?
    private(set) var title: String = ""
    
    var subtitle: String { "\(title.count)/\(maxWordCount) characters" }
    
    func updateTitle(_ title: String) {
        self.title = title
        delegate?.livecastTitleValidator(onTitleChanged: title)
    }
    
    func canStartStreaming() -> Bool {
        return title.count > minWordCount && title.count <= maxWordCount
    }

    func validateTitleInput(newTitle: String) -> Bool {
        if newTitle.count <= maxWordCount {
            updateTitle(newTitle)
            return true
        }
        
        return false
    }
}
