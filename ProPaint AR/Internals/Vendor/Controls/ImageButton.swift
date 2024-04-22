//
//  ImageButton.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/3/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable public class ImageButton: UIControl {
    var imageView = UIImageView()
    private var button = UIButton()
    private var widthConstraint: NSLayoutConstraint?

    @IBInspectable var cornerRadius: CGFloat = 15 {
        didSet {
            refreshCorners(value: cornerRadius)
        }
    }

    @IBInspectable var iconWidth: CGFloat = 32 {
        didSet {
            widthConstraint?.constant = iconWidth
        }
    }
    
    @IBInspectable var iconColor: UIColor = .white {
        didSet {
            imageView.tintColor = iconColor
        }
    }

    @IBInspectable var iconImage: UIImage? {
        didSet {
            imageView.image = iconImage
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    override public func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        sharedInit()
    }

    private func sharedInit() {
        contentVerticalAlignment = .fill
        contentMode = .center
        
        refreshCorners(value: cornerRadius)

        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        imageView.image = iconImage

        addSubview(imageView)
        addSubview(button)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.0)
        ])
        widthConstraint = imageView.widthAnchor.constraint(equalToConstant: iconWidth)
        widthConstraint?.isActive = true

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor)
        ])
    }

    private func refreshCorners(value: CGFloat) {
        layer.cornerRadius = value
        layer.masksToBounds = value > 0
    }

    @objc private func buttonAction() {
        sendActions(for: .touchUpInside)
    }
}
