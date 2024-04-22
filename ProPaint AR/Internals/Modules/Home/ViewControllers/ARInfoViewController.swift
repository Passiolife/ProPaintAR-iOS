//
//  ARInfoViewController.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/3/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Bugsnag
import Kingfisher
import UIKit

protocol ARInfoViewControllerDelegate: AnyObject {
    func dismiss(_ controller: ARInfoViewController)
}

class ARInfoViewController: UIViewController, Trackable {
    private var contentViewController: UIViewController?
    weak var delegate: ARInfoViewControllerDelegate?
    var methodInfo: ARMethodInfo?
    var customizationRepo: CustomizationRepo?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var imagesStackView: UIStackView!
    @IBOutlet weak var imageLeft: UIImageView!
    @IBOutlet weak var imageTitleLeft: UILabel!
    @IBOutlet weak var imageRight: UIImageView!
    @IBOutlet weak var imageTitleRight: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var containerView: RoundedView!
    @IBOutlet weak var backgroundOverlay: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyUICustomization()
        Bugsnag.leaveBreadcrumb(withMessage: "ARInfo: Started")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let methodInfo = methodInfo {
            configure(info: methodInfo)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        trackScreenView()
    }

    override func show(_ vc: UIViewController, sender: Any?) {
        contentViewController?.remove()
        contentViewController? = vc
        add(vc)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "ARInfo: closed")
        delegate?.dismiss(self)
    }
    
    private func configure(info: ARMethodInfo) {
        titleLabel.text = info.arType.rawValue + " Info"
        descriptionText.text = info.description
        let hasImages = info.imageLeft != nil || info.imageRight != nil
        imagesStackView.isHidden = !hasImages
        
        if let leftImageName = info.imageLeft {
            imageLeft.image = UIImage(named: leftImageName)
        }
        if let leftImageTitle = info.imageTitleLeft {
            imageTitleLeft.text = leftImageTitle
        }
        if let rightImageName = info.imageRight {
            imageRight.image = UIImage(named: rightImageName)
        }
        if let rightImageTitle = info.imageTitleRight {
            imageTitleRight.text = rightImageTitle
        }
    }
    
    private func applyUICustomization() {
        guard let customizationRepo = customizationRepo
        else { return }
        
        let uiOptions = customizationRepo.options.uiOptions
        let textColor = uiOptions.colors.text.color
        let buttonTextColor = uiOptions.colors.buttonText.color
        let buttonColor = uiOptions.colors.button.color
        let highlightedColor = uiOptions.colors.highlighted.color
        let backgroundResource = uiOptions.backgroundImage
        let backgroundImageOverlay = uiOptions.colors.backgroundImageOverlay.color
        let titleSize: CGFloat = 24
        let descriptionSize: CGFloat = 16
        let leftImageTitleSize: CGFloat = 16
        let rightImageTitleSize: CGFloat = 16
        
        backButton.titleLabel?.font = uiOptions.font.font(with: 16)
        backButton.setTitleColor(buttonTextColor, for: .normal)
        backButton.backgroundColor = buttonColor
        
        titleLabel.font = uiOptions.font.font(with: titleSize)
        titleLabel.textColor = textColor
        descriptionText.font = uiOptions.font.font(with: descriptionSize)
        descriptionText.textColor = textColor
        imageTitleLeft.font = uiOptions.font.font(with: leftImageTitleSize)
        imageTitleLeft.textColor = textColor
        imageTitleRight.font = uiOptions.font.font(with: rightImageTitleSize)
        imageTitleRight.textColor = textColor
        imageLeft.layer.borderColor = highlightedColor.cgColor
        imageRight.layer.borderColor = highlightedColor.cgColor
        
        backgroundImage.setImage(with: backgroundResource)
        backgroundOverlay.backgroundColor = backgroundImageOverlay
        
        containerView.backgroundColor = uiOptions.colors.frameBackground.color
    }
}

private typealias AnalyticsTracking = ARInfoViewController
extension AnalyticsTracking {
    private func trackScreenView() {
        guard let methodInfo = methodInfo
        else { return }
        
        switch methodInfo.arType {
        case .roomplan:
            trackScreen(name: "ar info view roomplan")
            
        case .lidar:
            trackScreen(name: "ar info view lidar")
            
        case .floorplan:
            trackScreen(name: "ar info view floorplan")
            
        case .swatch:
            trackScreen(name: "ar info view legacy")
            
        case .shader:
            trackScreen(name: "ar info view shader paint")
            
        case .mlsdk:
            trackScreen(name: "ar info view mlsdk")
        }
    }
}
