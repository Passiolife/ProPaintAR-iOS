//
//  ShadowView.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 16/05/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

final class ShadowView: UIView {
    var shadow: PaintItemShadow? {
        didSet {
            configure(with: shadow, cornerRadius: cornerRadius)
        }
    }

    var cornerRadius: CGSize = .zero
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = .init(
            roundedRect: self.bounds,
            cornerWidth: cornerRadius.width,
            cornerHeight: cornerRadius.height,
            transform: nil
        )
    }

    func configure(with shadow: PaintItemShadow?, cornerRadius: CGSize) {
        guard let shadow = shadow
        else { return }
        layer.masksToBounds = false
        layer.shadowColor = shadow.shadowColor
        layer.shadowOpacity = shadow.shadowOpacity
        layer.shadowOffset = shadow.shadowOffset
        layer.shadowRadius = shadow.shadowRadius
    }
}
