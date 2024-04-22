//
//  UIButton+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 8/15/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import Kingfisher
import UIKit

extension UIButton {
    public func setImage(
        with imageData: (ImageData?, UIImage?),
        placeholder: UIImage? = nil,
        for state: UIControl.State
    ) {
        if let systemImage = imageData.1 {
            let tinted = systemImage.withRenderingMode(.alwaysTemplate)
            self.setImage(tinted, for: state)
            if let tintColor = imageData.0?.tintColor {
                self.tintColor = tintColor
            }
        } else if let imageData = imageData.0 {
            kf.setImage(with: imageData.resource,
                        for: state,
                        placeholder: placeholder,
                        options: nil,
                        progressBlock: nil) { result in
                switch result {
                case .success(let image):
                    if let tintColor = imageData.tintColor {
                        let tinted = image.image.withRenderingMode(.alwaysTemplate)
                        self.setImage(tinted, for: state)
                        self.tintColor = tintColor
                    } else {
                        self.setImage(image.image.withRenderingMode(.alwaysOriginal), for: state)
                        self.tintColor = nil
                    }
                    
                case .failure: break
                }
            }
        }
    }
}
