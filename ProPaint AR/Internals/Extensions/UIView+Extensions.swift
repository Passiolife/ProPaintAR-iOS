//
//  UIView+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/3/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func roundCorners(radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = radius > 0
    }
    
    func addParallax(amount: Double) {
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount

        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        addMotionEffect(group)
    }
}

extension UIView {
    func screenshotForCroppingRect(croppingRect: CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(croppingRect.size,
                                               false,
                                               UIScreen.main.scale)
        
        guard let context = UIGraphicsGetCurrentContext()
        else { return nil }
        
        context.translateBy(x: -croppingRect.origin.x, y: -croppingRect.origin.y)
        self.layoutIfNeeded()
        self.layer.render(in: context)
        
        let screenshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshotImage
    }
    
    @objc var screenshot: UIImage? {
        self.screenshotForCroppingRect(croppingRect: self.bounds)
    }
}
