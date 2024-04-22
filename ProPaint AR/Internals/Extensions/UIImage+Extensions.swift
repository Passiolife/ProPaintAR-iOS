//
//  UIImage+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 7/6/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    class func imageWithColor(color: UIColor, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        if context == nil {
            return nil
        }
        color.set()
        context?.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIImage {
    class func verticalAppendedTotalImageSizeFromImagesArray(imagesArray: [UIImage]) -> CGSize {
        var totalSize = CGSize.zero
        for im in imagesArray {
            let imSize = im.size
            totalSize.height += imSize.height
            totalSize.width = max(totalSize.width, imSize.width)
        }
        return totalSize
    }
    
    class func verticalImageFromArray(imagesArray: [UIImage]) -> UIImage? {
        var unifiedImage: UIImage?
        let totalImageSize = self.verticalAppendedTotalImageSizeFromImagesArray(imagesArray: imagesArray)
        
        UIGraphicsBeginImageContextWithOptions(totalImageSize, false, 0)
        
        var imageOffsetFactor: CGFloat = 0
        
        for img in imagesArray {
            img.draw(at: CGPoint(x: 0, y: imageOffsetFactor))
            imageOffsetFactor += img.size.height
        }
        unifiedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return unifiedImage
    }
}

extension UIImage {
    convenience init?(coreImage: CIImage) {
        let context = CIContext(options: nil)
        guard let cgImage: CGImage = context.createCGImage(coreImage, from: coreImage.extent)
        else {
            fatalError("Error creating UIImage from CIImage")
        }
        self.init(cgImage: cgImage)
    }

    func croppedWith(rect: CGRect) -> UIImage? {
        guard let imageRef = self.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: imageRef)
    }

    func scaleImageTo(size: CGSize) -> UIImage? {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        guard let context = UIGraphicsGetCurrentContext()
        else { return nil }

        context.interpolationQuality = .none

        self.draw(in: CGRect(origin: CGPoint.zero, size: size))

        guard let imageRef = context.makeImage()
        else { return nil }
        
        let newImage = UIImage(cgImage: imageRef, scale: scale, orientation: .up)
        UIGraphicsEndImageContext()

        return newImage
    }

    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        guard status == kCVReturnSuccess,
        let pixelBuffer = pixelBuffer
        else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        guard let context = context
        else { return nil }
        
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }
}
