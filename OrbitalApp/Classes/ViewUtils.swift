//
//  ViewUtils.swift
//  orbital
//
//  Created by Ryoichiro Oka on 11/9/19.
//  Copyright © 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func capture() -> UIImage? {
        UIGraphicsBeginImageContext(self.frame.size)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension Bundle {
    func loadView<T>(_ type: T.Type, fromNib name: String) -> T? {
        self.loadNibNamed(name, owner: nil, options: nil)?.first as? T
    }
}
