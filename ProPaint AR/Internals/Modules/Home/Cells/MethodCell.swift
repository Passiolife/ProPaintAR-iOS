//
//  MethodCell.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/22/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

class MethodCell: FSPagerViewCell {
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var continueButton: StyledButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var infoImage: UIImageView!
    @IBOutlet weak var iconContainer: RoundedView!
    @IBOutlet weak var infoContainer: RoundedView!
    
    var continueCallback: ((UIButton) -> Void)?
    var infoCallback: ((UIButton) -> Void)?
    
    func configure(
        index: Int,
        method: ARMethod,
        customizationRepo: CustomizationRepo?
    ) {
        iconLabel.text = method.type.rawValue
        descriptionText.text = method.description
        
        guard let customizationRepo = customizationRepo
        else {
            iconImage.image = UIImage(named: method.iconName)
            return
        }
        
        let uiOptions = customizationRepo.options.uiOptions
        let textColor = uiOptions.colors.text.color
        let buttonTextColor = uiOptions.colors.buttonText.color
        let buttonColor = uiOptions.colors.button.color
        let subframeBackgroundColor = uiOptions.colors.subframeBackground.color
        
        continueButton.titleLabel?.font = uiOptions.font.font(with: 14 )
        continueButton.backgroundColor = buttonColor
        continueButton.setTitleColor(buttonTextColor, for: .normal)
        
        let icon = uiOptions.methodIcons.allImages[index]
        iconImage.setImage(with: icon,
                           placeholder: UIImage(named: method.iconName))
        
        iconLabel.font = uiOptions.font.font(with: 18)
        iconLabel.textColor = textColor
        
        descriptionText.font = uiOptions.font.font(with: 14)
        descriptionText.textColor = textColor
        
        let infoIcon = uiOptions.buttonIcons.methodInfoIcon
        infoImage.setImage(with: infoIcon)
        
        iconContainer.backgroundColor = subframeBackgroundColor
        infoContainer.backgroundColor = subframeBackgroundColor
    }
    
    @IBAction func continueAction(_ sender: UIButton) {
        continueCallback?(sender)
    }
    
    @IBAction func showInfoAction(_ sender: UIButton) {
        infoCallback?(sender)
    }
}
