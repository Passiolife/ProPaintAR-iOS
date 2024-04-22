//
//  OcclusionWizardStartCell.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/26/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Bugsnag
import UIKit

protocol OcclusionWizardStartCellDelegate: AnyObject {
    func getStartedTapped(_ sender: OcclusionWizardStartCell)
}

class OcclusionWizardStartCell: FSPagerViewCell {
    weak var delegate: OcclusionWizardStartCellDelegate?
    
    @IBOutlet weak var getStartedButton: RoundedButton!
    @IBOutlet weak var instructionsText: UITextView!
    
    @IBAction func getStartedTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Occlusions: get started tapped")
        delegate?.getStartedTapped(self)
    }
    
    func configure(with customizationRepo: CustomizationRepo?) {
        guard let customizationRepo = customizationRepo
        else { return }
        
        let uiOptions = customizationRepo.options.uiOptions
        let buttonColor = uiOptions.colors.button.color
        let buttonTextColor = uiOptions.colors.buttonText.color
        let textColor = uiOptions.colors.text.color
        getStartedButton.backgroundColor = buttonColor
        getStartedButton.setTitleColor(buttonTextColor, for: .normal)
        
        getStartedButton.titleLabel?.font = uiOptions.font.font(with: 16)
        instructionsText.font = uiOptions.font.font(with: 16)
        instructionsText.textColor = textColor
    }
}
