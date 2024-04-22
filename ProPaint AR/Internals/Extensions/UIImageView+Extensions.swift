//
//  UIImageView+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 8/10/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import Kingfisher
import UIKit

extension UIImageView {
    public func setImage(with imageData: (ImageData?, UIImage?), placeholder: Placeholder? = nil) {
        if let placeholder = placeholder as? KFCrossPlatformImage {
            image = placeholder
        }
        if let systemImage = imageData.1 {
            image = systemImage
            self.tintColor = imageData.0?.tintColor
        } else if let imageData = imageData.0 {
            kf.setImage(with: imageData.resource, placeholder: placeholder, options: nil) { result in
                switch result {
                case .success(let image):
                    if let tintColor = imageData.tintColor {
                        let tinted = image.image.withRenderingMode(.alwaysTemplate)
                        self.tintColor = tintColor
                        self.image = tinted
                    } else {
                        self.image = image.image.withRenderingMode(.alwaysOriginal)
                        self.tintColor = nil
                    }
                    
                case .failure: break
                }
            }
        }
    }
}
