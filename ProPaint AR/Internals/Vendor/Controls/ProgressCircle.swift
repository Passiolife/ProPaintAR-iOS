//
//  ProgressCircle.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/1/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class ProgressCircle: UIControl {
    private var startPoint = CGFloat(-Double.pi / 2)
    private var endPoint = CGFloat(3 * Double.pi / 2)
    let subLayer = CAShapeLayer()
    let textLayer = LCTextLayer()
    let lineLayer = CAShapeLayer()
    
    @IBInspectable var buttonTitle: String = "" {
        didSet {
            textLayer.string = buttonTitle
        }
    }
    
    @IBInspectable var buttonTitleColor: UIColor = .text {
        didSet {
            textLayer.foregroundColor = buttonTitleColor.cgColor
        }
    }
    
    @IBInspectable var buttonTitleFontSize: CGFloat = 14 {
        didSet {
            textLayer.fontSize = buttonTitleFontSize
        }
    }
    
    @IBInspectable var buttonFillColor: UIColor = .overlayBackground {
        didSet {
            subLayer.fillColor = buttonFillColor.cgColor
        }
    }
    
    @IBInspectable var lineColor: UIColor = .buttonText {
        didSet {
            lineLayer.strokeColor = lineColor.cgColor
        }
    }
    
    @IBInspectable var lineWidth: CGFloat = 6 {
        didSet {
            lineLayer.lineWidth = lineWidth
        }
    }
    
    @IBInspectable var progress: CGFloat = 0.5 {
        didSet {
            progress = min(1, max(progress, 0))
            lineLayer.strokeEnd = progress
        }
    }
    
    override var layer: CAShapeLayer {
        // swiftlint:disable:next force_cast
        super.layer as! CAShapeLayer
    }

    override class var layerClass: AnyClass {
        CAShapeLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.fillColor = nil
        lineLayer.fillColor = nil
        lineLayer.lineWidth = lineWidth
        lineLayer.lineCap = .round
        lineLayer.lineJoin = .round
        
        subLayer.fillColor = buttonFillColor.cgColor
        
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.foregroundColor = buttonTitleColor.cgColor
        textLayer.font = UIFont(name: "SFProText-Regular", size: buttonTitleFontSize)
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        
        let height = bounds.size.height
        let yDiff = (height - buttonTitleFontSize) / 2 - buttonTitleFontSize / 10
        textLayer.frame = frame
        textLayer.position = CGPoint(x: 0, y: yDiff + 80)
        textLayer.string = buttonTitle
        
        setPath()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        sendActions(for: .touchUpInside)
    }
    
    func update(progress: CGFloat, animated: Bool = true) {
        self.progress = min(1, max(progress, 0))
        if !animated {
            lineLayer.removeAllAnimations()
        }
    }

    private func setPath() {
        let radius = frame.width / 2 - lineWidth / 2
        let center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        
        subLayer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: lineWidth,
                                                            dy: lineWidth)).cgPath
        subLayer.bounds = bounds
        subLayer.position = center
        
        textLayer.bounds = bounds
        textLayer.position = center
        
        lineLayer.path = UIBezierPath(arcCenter: center,
                                      radius: radius,
                                      startAngle: startPoint,
                                      endAngle: endPoint,
                                      clockwise: true).cgPath
        lineLayer.bounds = bounds
        lineLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        lineLayer.strokeColor = lineColor.cgColor
        lineLayer.strokeStart = 0
        
        layer.addSublayer(subLayer)
        layer.addSublayer(textLayer)
        layer.addSublayer(lineLayer)
    }
}
