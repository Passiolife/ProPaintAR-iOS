//
//  WallColorCollectionCell.swift
//  Remodel-AR WL
//
//  Created by Tamás Sengel on 6/28/21.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

class WallColorCollectionCell: UICollectionViewCell {
    // MARK: - Outlets

    @IBOutlet weak var colorView: ShadowView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var darkOverlayView: UIView!
    @IBOutlet var textureImageView: UIImageView!

    private var colorCornerRadius: CGFloat = 10 {
        didSet {
            colorView.cornerRadius = CGSize(width: colorCornerRadius,
                                            height: colorCornerRadius)
        }
    }
    private let colorBorderLayer = CALayer()
    
    var distanceFromCenter: CGFloat = 0 {
        didSet {
            updateDistanceFromCenter(oldDistance: oldValue)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        colorBorderLayer.frame = colorView.bounds
        colorView.setNeedsLayout()
    }
}

extension WallColorCollectionCell {
    func configure(
        with paint: Paint,
        borderWidth: CGFloat?,
        borderColor: CGColor?,
        paintImage: UIImage?
    ) {
        colorView.backgroundColor = paint.color
        colorBorderLayer.borderWidth = borderWidth ?? 0.0
        textureImageView.image = paintImage ?? paint.texture
        CALayer.performWithoutAnimation {
            colorBorderLayer.borderColor = borderColor
        }
        nameLabel.text = ""
    }

    func configure(with cornerRadius: CGFloat?) {
        guard let sublayers = colorView.layer.sublayers,
              !sublayers.contains(colorBorderLayer),
              let cornerRadius = cornerRadius,
              cornerRadius > 0.0
        else { return }
        DispatchQueue.main.async { [weak self] in
            self?.colorView.layer.cornerRadius = cornerRadius
            self?.colorBorderLayer.cornerRadius = cornerRadius
            self?.textureImageView.layer.cornerRadius = cornerRadius
        }
        colorCornerRadius = cornerRadius
        colorView.cornerRadius = CGSize(width: cornerRadius, height: cornerRadius)
        colorView.layer.addSublayer(colorBorderLayer)
    }

    func configure(with shadow: PaintItemShadow?) {
        guard colorView.shadow != nil
        else {
            colorView.shadow = shadow
            return
        }
    }
}

extension WallColorCollectionCell {
    func handleFewPaintBorder(with selectedPaintId: String, paint: Paint) {
        colorBorderLayer.opacity = selectedPaintId == paint.id ? 1 : 0
    }
    func clearBorderColor() {
        CALayer.performWithoutAnimation {
            colorBorderLayer.opacity = 0
        }
    }
}

extension WallColorCollectionCell {
    fileprivate func updateDistanceFromCenter(oldDistance: CGFloat? = nil) {
        let opacity = getColorBorderOpacity(distance: distanceFromCenter)
        if let oldDistance = oldDistance {
            let oldOpacity = getColorBorderOpacity(distance: oldDistance)
            
            if oldOpacity == opacity {
                return
            }
        }
        CALayer.performWithoutAnimation {
            colorBorderLayer.opacity = Float(opacity)
        }
        nameLabel.alpha = opacity
    }

    fileprivate func getColorBorderOpacity(distance: CGFloat) -> CGFloat {
        let threshold = 26.0
        return max(0, (threshold - abs(distance)) / threshold)
    }
}

extension CALayer {
    class func performWithoutAnimation(_ callback: () -> Void) {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        callback()
        CATransaction.commit()
    }
}
