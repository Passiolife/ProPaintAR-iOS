//
//  OcclusionWizardThresholdCell.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/26/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Bugsnag
import UIKit

protocol OcclusionWizardThresholdCellDelegate: AnyObject {
    func thresholdUpdated(threshold: Float, sender: OcclusionWizardThresholdCell)
    func resetOcclusion(_ sender: OcclusionWizardThresholdCell)
    func adjustColors(_ sender: OcclusionWizardThresholdCell)
}

class OcclusionWizardThresholdCell: FSPagerViewCell {
    weak var delegate: OcclusionWizardThresholdCellDelegate?
    
    @IBOutlet weak var thresholdSlider: UISlider!
    @IBOutlet weak var resetOcclusionsButton: RoundedButton!
    @IBOutlet weak var adjustColorsButton: RoundedButton!
    @IBOutlet weak var instructionsText: UITextView!
    
    @IBAction func adjustColorsTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Occlusions: threshold adjust colors")
        delegate?.adjustColors(self)
    }
    
    @IBAction func resetTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Occlusions: threshold reset")
        delegate?.resetOcclusion(self)
    }
    
    @IBAction func thresholdUpdated(_ sender: UISlider) {
        delegate?.thresholdUpdated(threshold: sender.value, sender: self)
    }
    
    func configure(with threshold: Float) {
        thresholdSlider.value = threshold
    }
    
    func configure(with customizationRepo: CustomizationRepo?) {
        guard let customizationRepo = customizationRepo
        else {
            if let maxColor = thresholdSlider.maximumTrackTintColor,
               let thumbColor = thresholdSlider.thumbTintColor {
                let minColor = [maxColor, thumbColor].average
                thresholdSlider.minimumTrackTintColor = minColor
            }
            return
        }
        
        let uiOptions = customizationRepo.options.uiOptions
        let buttonColor = uiOptions.colors.button.color
        let buttonTextColor = uiOptions.colors.buttonText.color
        let textColor = uiOptions.colors.text.color
        let highlightedColor = uiOptions.colors.highlighted.color
        let unhighlightedColor = uiOptions.colors.unhighlighted.color
        
        adjustColorsButton.backgroundColor = buttonColor
        adjustColorsButton.setTitleColor(buttonTextColor, for: .normal)
        
        resetOcclusionsButton.backgroundColor = buttonColor
        resetOcclusionsButton.setTitleColor(buttonTextColor, for: .normal)
        
        adjustColorsButton.titleLabel?.font = uiOptions.font.font(with: 16)
        resetOcclusionsButton.titleLabel?.font = uiOptions.font.font(with: 16)
        instructionsText.font = uiOptions.font.font(with: 16)
        instructionsText.textColor = textColor
        
        let minColor = [unhighlightedColor, highlightedColor].average
        thresholdSlider.minimumTrackTintColor = minColor
        thresholdSlider.maximumTrackTintColor = unhighlightedColor
        thresholdSlider.thumbTintColor = highlightedColor
    }
}
