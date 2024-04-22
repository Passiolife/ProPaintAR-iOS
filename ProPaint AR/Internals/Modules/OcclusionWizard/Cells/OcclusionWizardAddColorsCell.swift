//
//  OcclusionWizardAddColorsCell.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/26/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Bugsnag
import Kingfisher
import UIKit

protocol OcclusionWizardAddColorsCellDelegate: AnyObject {
    func continueTapped(_ sender: OcclusionWizardAddColorsCell)
    func colorsUpdated(colors: [UIColor], sender: OcclusionWizardAddColorsCell)
}

class OcclusionWizardAddColorsCell: FSPagerViewCell {
    weak var delegate: OcclusionWizardAddColorsCellDelegate?
    
    private var selectedIndex: Int = -1
    
    private var state: AddColorState = .viewingColor {
        didSet {
            updateView()
        }
    }
    
    @IBOutlet var trashButtons: [RoundedButton]!
    @IBOutlet var swatches: [ColorSwatch]!
    @IBOutlet var swatchContainers: [UIView]!
    @IBOutlet weak var instructionsText: UILabel!
    @IBOutlet weak var addColorButton: RoundedButton!
    @IBOutlet weak var continueButton: RoundedButton!
    
    private var colors: [UIColor] = [] {
        didSet {
            guard swatchContainers.count == 3
            else { return }
            
            delegate?.colorsUpdated(colors: colors, sender: self)
            for index in 0...2 {
                swatchContainers[index].isHidden = index != selectedIndex
                trashButtons[index].isHidden = index != selectedIndex
                swatches[index].isActive = index == selectedIndex
            }
            for (index, color) in colors.enumerated() {
                swatchContainers[index].isHidden = false
                swatches[index].backgroundColor = color
            }
        }
    }

    func configureTrashButtonImage(image: (ImageData?, UIImage?)) {
        trashButtons.forEach({ $0.imageView?.setImage(with: image, placeholder: nil) })
    }
    
    @IBAction func addColorTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Occlusions: add color tapped")
        state = .addingColor
    }
    
    @IBAction func colorSwatchTapped(_ sender: ColorSwatch) {
        Bugsnag.leaveBreadcrumb(withMessage: "Occlusions: color swatch tapped \(sender.tag)")
        deselectColorSwatches()
        selectedIndex = sender.tag
        trashButtons[selectedIndex].isHidden = false
        sender.isActive = true
    }
    
    @IBAction func deleteSwatchTapped(_ sender: UIButton) {
        Bugsnag.leaveBreadcrumb(withMessage: "Occlusions: delete swatch tapped \(sender.tag)")
        selectedIndex = -1
        
        guard colors.count > sender.tag
        else { return }
        
        colors.remove(at: sender.tag)
        state = .viewingColor
    }
    
    @IBAction func continueTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Occlusions: add color continue")
        delegate?.continueTapped(self)
    }
    
    func reset() {
        selectedIndex = -1
        configure(with: [], state: .viewingColor)
    }
    
    func configure(with colors: [UIColor], state: AddColorState = .viewingColor) {
        let colors = colors.prefix(3)
        self.colors = Array(colors)
        self.state = state
        deselectColorSwatches()
    }
    
    func configure(with customizationRepo: CustomizationRepo?) {
        guard let customizationRepo = customizationRepo
        else { return }
        
        let uiOptions = customizationRepo.options.uiOptions
        let buttonColor = uiOptions.colors.button.color
        let buttonTextColor = uiOptions.colors.buttonText.color
        let textColor = uiOptions.colors.text.color
        let selectedColor = uiOptions.colors.highlighted.color
        let deselectedColor = uiOptions.colors.unhighlighted.color
        
        addColorButton.backgroundColor = buttonColor
        addColorButton.setTitleColor(buttonTextColor, for: .normal)
        
        continueButton.backgroundColor = buttonColor
        continueButton.setTitleColor(buttonTextColor, for: .normal)
        
        let trash = uiOptions.buttonIcons.shaderOcclusionColorTrashIcon
        configureTrashButtonImage(image: trash)
        
        addColorButton.titleLabel?.font = uiOptions.font.font(with: 16)
        continueButton.titleLabel?.font = uiOptions.font.font(with: 16)
        instructionsText.textColor = textColor
        instructionsText.font = uiOptions.font.font(with: 16)
        
        for index in 0...2 {
            swatches[index].outlineSelectedColor = selectedColor
            swatches[index].outlineDeselectedColor = deselectedColor
        }
    }
    
    func updateView() {
        instructionsText.text = instructions
        addColorButton.isHidden = !addButtonVisible
        continueButton.isHidden = !continueButtonVisible
    }
    
    func addedColor(color: UIColor) {
        if state == .addingColor {
            deselectColorSwatches()
            selectedIndex = colors.count
            colors.append(color)
            state = colors.count < 3 ? .viewingColor : .allColorsAdded
        } else if !colors.isEmpty {
            updateSelectedColor(color: color)
        }
    }
    
    private func updateSelectedColor(color: UIColor) {
        for index in 0..<colors.count {
            let swatch = swatches[index]
            if swatch.isActive {
                swatch.backgroundColor = color
                var colorsCopy = colors
                colorsCopy.remove(at: index)
                colorsCopy.insert(color, at: index)
                colors = colorsCopy
                return
            }
        }
    }
    
    private func deselectColorSwatches() {
        selectedIndex = -1
        for index in 0...2 {
            swatches[index].isActive = false
            trashButtons[index].isHidden = true
        }
    }
}

extension OcclusionWizardAddColorsCell {
    enum AddColorState: String {
        case viewingColor
        case addingColor
        case allColorsAdded
    }
    
    var instructions: String {
        switch state {
        case .viewingColor:
            return "Add some colors."
        case .addingColor:
            return "Tap on the wall to add a color."
        case .allColorsAdded:
            return "Tap on a color swatch to change it's color."
        }
    }
    
    var addButtonVisible: Bool {
        switch state {
        case .allColorsAdded: return false
        default: return true
        }
    }
    
    var continueButtonVisible: Bool {
        !colors.isEmpty
    }
}
