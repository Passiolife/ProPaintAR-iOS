//
//  CMSampleBuffer+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/6/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import AVFoundation
import UIKit
import VideoToolbox

extension CMSampleBuffer {
    func image(orientation: AVCaptureVideoOrientation) -> UIImage? {
        if let imageBuffer = CMSampleBufferGetImageBuffer(self) {
            let context = CIContext()
            var ciImage = CIImage(cvPixelBuffer: imageBuffer)
            
            switch orientation {
            case .portrait:
                ciImage = ciImage.oriented(.right)
                
            case .portraitUpsideDown:
                ciImage = ciImage.oriented(.left)
                
            case .landscapeRight:
                ciImage = ciImage.oriented(.up)
            
            case .landscapeLeft:
                ciImage = ciImage.oriented(.down)
            default: break
            }
            
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}
