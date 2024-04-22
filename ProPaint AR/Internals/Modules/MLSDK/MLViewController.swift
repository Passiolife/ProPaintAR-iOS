//
//  MLViewController.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/2/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import Kingfisher
import UIKit

protocol MLViewControllerDelegate: AnyObject {
    func dismiss(_ controller: MLViewController)
    func methodSelected(method: MLMethod, controller: MLViewController)
}

class MLViewController: UIViewController, Trackable {
    @IBOutlet private weak var environmentImageView: UIImageView!
    @IBOutlet private weak var surfaceImageView: UIImageView!
    @IBOutlet private weak var abnormalityImageView: UIImageView!
    @IBOutlet weak var homeButton: ImageButton!

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var environmentTitleLabel: UILabel!
    @IBOutlet weak var surfaceTitleLabel: UILabel!
    @IBOutlet weak var abnormalityTitleLabel: UILabel!
    
    @IBOutlet weak var environmentDescriptionText: VerticallyCenteredTextView!
    @IBOutlet weak var surfaceDescriptionText: VerticallyCenteredTextView!
    @IBOutlet weak var abnormalityDescriptionText: VerticallyCenteredTextView!
    
    @IBOutlet weak var infoContainer: RoundedView!
    @IBOutlet weak var environmentContainer: RoundedView!
    @IBOutlet weak var surfaceContainer: RoundedView!
    @IBOutlet weak var abnormalityContainer: RoundedView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var backgroundOverlay: UIView!
    
    weak var delegate: MLViewControllerDelegate?
    private var cancellables = Set<AnyCancellable>()
    var customizationRepo: CustomizationRepo?

    override func viewDidLoad() {
        super.viewDidLoad()
        trackScreen(name: "mlsdk methods")
        applyUICustomization()
    }
}

private typealias Configuration = MLViewController
extension Configuration {
    private func applyUICustomization() {
        guard let customizationRepo = customizationRepo
        else { return }
        
        let uiOptions = customizationRepo.options.uiOptions
        let textColor = uiOptions.colors.text.color
        let frameColor = uiOptions.colors.frameBackground.color
        let mlMethodIcons = uiOptions.buttonIcons.mlMethodIcons
        let homeResource = uiOptions.buttonIcons.homeIcon
        let environmentResource = mlMethodIcons.environmentIcon
        let surfaceResource = mlMethodIcons.surfaceIcon
        let abnormalityResource = mlMethodIcons.abnormalityIcon
        let backgroundResource = uiOptions.backgroundImage
        let backgroundImageOverlay = uiOptions.colors.backgroundImageOverlay.color
        let titleFontSize: CGFloat = 17
        let descriptionFontSize: CGFloat = 16
        
        homeButton.imageView.setImage(with: homeResource, placeholder: nil)
        homeButton.backgroundColor = frameColor
        environmentImageView.setImage(with: environmentResource, placeholder: nil)
        surfaceImageView.setImage(with: surfaceResource, placeholder: nil)
        abnormalityImageView.setImage(with: abnormalityResource, placeholder: nil)
        titleLabel.font = uiOptions.font.font(with: titleFontSize)
        titleLabel.textColor = textColor
        environmentTitleLabel.font = uiOptions.font.font(with: titleFontSize)
        environmentTitleLabel.textColor = textColor
        surfaceTitleLabel.font = uiOptions.font.font(with: titleFontSize)
        surfaceTitleLabel.textColor = textColor
        abnormalityTitleLabel.font = uiOptions.font.font(with: titleFontSize)
        abnormalityTitleLabel.textColor = textColor
        environmentDescriptionText.font = uiOptions.font.font(with: descriptionFontSize)
        environmentDescriptionText.textColor = textColor
        surfaceDescriptionText.font = uiOptions.font.font(with: descriptionFontSize)
        surfaceDescriptionText.textColor = textColor
        abnormalityDescriptionText.font = uiOptions.font.font(with: descriptionFontSize)
        abnormalityDescriptionText.textColor = textColor
        
        infoContainer.backgroundColor = frameColor
        environmentContainer.backgroundColor = frameColor
        surfaceContainer.backgroundColor = frameColor
        abnormalityContainer.backgroundColor = frameColor
        
        backgroundImage.setImage(with: backgroundResource)
        backgroundOverlay.backgroundColor = backgroundImageOverlay
    }
}

private typealias IBActions = MLViewController
extension IBActions {
    @IBAction func homeTapped(_ sender: Any) {
        trackEvent(name: "mlsdk methods closed", parameters: nil)
        delegate?.dismiss(self)
    }
    
    @IBAction func environmentSelected(_ sender: Any) {
        delegate?.methodSelected(method: .environment, controller: self)
    }
    
    @IBAction func surfaceSelected(_ sender: Any) {
        delegate?.methodSelected(method: .surface, controller: self)
    }
    
    @IBAction func abnormalitySelected(_ sender: Any) {
        delegate?.methodSelected(method: .abnormality, controller: self)
    }
}
