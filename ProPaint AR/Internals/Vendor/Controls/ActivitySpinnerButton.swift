//
//  ActivitySpinnerButton.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/11/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class ActivitySpinnerButton: UIControl {
    private var lastTouch = Date()
    private var font: UIFont?
    let subLayer = CAShapeLayer()
    let textLayer = LCTextLayer()
    let lineLayer = CAShapeLayer()
    
    @IBInspectable var buttonTitle: String = "Button" {
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
    
    @IBInspectable var lineWidth: CGFloat = 6 {
        didSet {
            lineLayer.lineWidth = lineWidth
        }
    }
    
    @IBInspectable var isAnimating: Bool = false {
        didSet {
            guard isAnimating != oldValue
            else { return }
            
            if isAnimating {
                startAnimating()
            } else {
                stopAnimating()
            }
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
        textLayer.font = font ?? UIFont(name: "SFProText-Regular", size: buttonTitleFontSize)
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        
        let height = bounds.size.height
        let yDiff = (height - buttonTitleFontSize) / 2 - buttonTitleFontSize / 10
        textLayer.frame = frame
        textLayer.position = CGPoint(x: 0, y: yDiff + 80)
        textLayer.string = buttonTitle
        textLayer.adjustsFontSizeToFitWidth = true
        
        setPath()
    }

    override func didMoveToWindow() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        sendActions(for: .touchUpInside)
    }
    
    public func setFont(font: UIFont) {
        self.font = font
        textLayer.font = font
    }
    
    private func startAnimating() {
        var time: CFTimeInterval = 0
        var times = [CFTimeInterval]()
        var start: CGFloat = 0
        var rotations = [CGFloat]()
        var strokeEnds = [CGFloat]()

        let poses = type(of: self).poses
        let totalSeconds = poses.reduce(0) { $0 + $1.secondsSincePriorPose }

        for pose in poses {
            time += pose.secondsSincePriorPose
            times.append(time / totalSeconds)
            start = pose.start
            rotations.append(start * 2 * .pi)
            strokeEnds.append(pose.length)
        }
        
        guard let lastTime = times.last
        else { return }

        times.append(lastTime)
        rotations.append(rotations[0])
        strokeEnds.append(strokeEnds[0])

        layer.addSublayer(lineLayer)
        
        animateKeyPath(keyPath: "strokeEnd", duration: totalSeconds, times: times, values: strokeEnds)
        animateKeyPath(keyPath: "transform.rotation", duration: totalSeconds, times: times, values: rotations)

        animateStrokeHueWithDuration(duration: totalSeconds * 5)
    }
    
    private func stopAnimating() {
        lineLayer.removeAllAnimations()
        lineLayer.removeFromSuperlayer()
    }

    @objc private func applicationWillEnterForeground(_ notification: NSNotification) {
        if isAnimating {
            startAnimating()
        } else {
            stopAnimating()
        }
    }
    
    private func setPath() {
        subLayer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: lineWidth,
                                                            dy: lineWidth)).cgPath
        subLayer.bounds = bounds
        subLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        
        textLayer.bounds = bounds
        textLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        
        lineLayer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: lineWidth / 2,
                                                             dy: lineWidth / 2)).cgPath
        lineLayer.bounds = bounds
        lineLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        
        layer.addSublayer(subLayer)
        layer.addSublayer(textLayer)
    }

    private func animateKeyPath(
        keyPath: String,
        duration: CFTimeInterval,
        times: [CFTimeInterval],
        values: [CGFloat]
    ) {
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.keyTimes = times as [NSNumber]?
        animation.values = values
        animation.calculationMode = .linear
        animation.duration = duration
        animation.repeatCount = Float.infinity
        lineLayer.add(animation, forKey: animation.keyPath)
    }

    private func animateStrokeHueWithDuration(duration: CFTimeInterval) {
        let count = 36
        let animation = CAKeyframeAnimation(keyPath: "strokeColor")
        animation.keyTimes = (0 ... count).map { NSNumber(value: CFTimeInterval($0) / CFTimeInterval(count)) }
        animation.values = (0 ... count).map {
            UIColor(hue: CGFloat($0) / CGFloat(count), saturation: 1, brightness: 1, alpha: 1).cgColor
        }
        animation.duration = duration
        animation.calculationMode = .linear
        animation.repeatCount = Float.infinity
        lineLayer.add(animation, forKey: animation.keyPath)
    }
}

extension ActivitySpinnerButton {
    struct Pose {
        let secondsSincePriorPose: CFTimeInterval
        let start: CGFloat
        let length: CGFloat
        
        init(_ secondsSincePriorPose: CFTimeInterval, _ start: CGFloat, _ length: CGFloat) {
            self.secondsSincePriorPose = secondsSincePriorPose
            self.start = start
            self.length = length
        }
    }

    class var poses: [Pose] {
        [
            Pose(0.0, 0.000, 0.7),
            Pose(0.6, 0.500, 0.5),
            Pose(0.6, 1.000, 0.3),
            Pose(0.6, 1.500, 0.1),
            Pose(0.2, 1.875, 0.1),
            Pose(0.2, 2.250, 0.3),
            Pose(0.2, 2.625, 0.5),
            Pose(0.2, 3.000, 0.7)
        ]
    }
}

class LCTextLayer: CATextLayer {
    // REF: http://lists.apple.com/archives/quartz-dev/2008/Aug/msg00016.html
    // CREDIT: David Hoerl - https://github.com/dhoerl
    // USAGE: To fix the vertical alignment issue that currently exists within the CATextLayer class. Change made to the yDiff calculation.

    var adjustsFontSizeToFitWidth = false
    
    override func draw(in context: CGContext) {
        let height = self.bounds.size.height
        let fontSize = self.fontSize
        let yDiff = (height - fontSize) / 2 - fontSize / 10

        context.saveGState()
        
        // Use -yDiff when in non-flipped coordinates (like macOS's default)
        context.translateBy(x: 0, y: yDiff)
        
        super.draw(in: context)
        context.restoreGState()
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        if adjustsFontSizeToFitWidth {
            fitToFrame()
        }
    }

    func fitToFrame() {
        var stringSize: CGSize {
            guard let string = string as? String,
                  let font = font as? UIFont,
                  let newFont = UIFont(name: font.fontName, size: fontSize)
            else { return .zero }
            
            return string.size(OfFont: newFont)
        }
        
        let inset: CGFloat = 30
        while frame.width < stringSize.width + inset {
            fontSize -= 1
        }
    }
}
