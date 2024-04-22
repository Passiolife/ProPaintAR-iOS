//
//  UIStoryboardNames.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/4/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIStoryboard {
    public enum Name: String {
        case Store
        case Home
        case ARMethods
        case MLMethods
    }
}

extension StoryboardLoadable where Self: UIViewController {
    public static func instantiate(fromStoryboardNamed name: UIStoryboard.Name) -> Self {
        let storyboard = UIStoryboard(name: name.rawValue, bundle: nil)
        return instantiate(fromStoryboard: storyboard)
    }
}
