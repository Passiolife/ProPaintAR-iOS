//
//  ScanOverlay.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/26/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class ScanOverlay: UIImageView {
    @IBInspectable var imageName: String = "" {
        didSet {
            initializeImages()
        }
    }

    @IBInspectable var animatedDuration: CGFloat = 4 {
        didSet {
            initializeImages()
        }
    }
    
    @IBInspectable var numberOfImages: Int = 0 {
        didSet {
            initializeImages()
        }
    }
    
    @IBInspectable var numberPadding: Int = 0 {
        didSet {
            initializeImages()
        }
    }
    
    private var previousHash: Int = 0

    private var images: [UIImage] {
        var images = [UIImage]()
        for index in 0..<numberOfImages {
            let imageName = "\(imageName)\(String(format: "%0\(numberPadding)d", index))"
            if let image = UIImage(named: imageName) {
                images.append(image)
            }
        }
        return images
    }
    
    private func initializeImages() {
        image = UIImage.animatedImage(with: images, duration: animatedDuration)
    }
}
