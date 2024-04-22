//
//  LidarOcclusionWizardViewController.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 4/27/23.
//  Copyright © 2023 Passio Inc. All rights reserved.
//

import Bugsnag
import Combine
import UIKit

protocol LidarOcclusionWizardViewControllerDelegate: AnyObject {
    func closeView(_ controller: LidarOcclusionWizardViewController)
}

class LidarOcclusionWizardViewController: UIViewController, Trackable {
    @IBOutlet weak var subviewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var subview: UIView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var scanButton: RoundedButton!
    @IBOutlet private weak var thresholdSlider: UISlider!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var resetButton: RoundedButton!
    
    private var isScanning = false
    private var didSucceed = false
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private weak var localData: LocalData?
    weak var delegate: LidarOcclusionWizardViewControllerDelegate?
    var customizationRepo: CustomizationRepo?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        subviewTopConstraint.constant = -subview.frame.height
//        configureLocalData()
        applyUICustomization()
        Bugsnag.leaveBreadcrumb(withMessage: "Lidar Occlusions: Started")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        trackScreen(name: "lidar occlusion wizard")
        openView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let threshold = localData?.threshold {
            thresholdSlider.value = threshold.interpolate(from: (min: -0.5, max: 0.5),
                                                          to: (min: 0, max: 1))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        trackEvent(name: "lidar occlusion wizard closed", parameters: nil)
    }
    
    @IBAction func resetAction(_ sender: Any) {
        localData?.resetLidarOcclusions.send()
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Lidar Occlusions: closed")
        setScanState(enabled: false)
        closeView()
    }
    
    @IBAction func scanTapped(_ sender: Any) {
        setScanState(enabled: !isScanning)
    }
    
    @IBAction func thresholdUpdated(_ sender: UISlider) {
        let threshold = sender.value.interpolate(from: (min: 0, max: 1),
                                                 to: (min: -0.5, max: 0.5))
        localData?.setThreshold(threshold: threshold)
    }
    
    private func setScanState(enabled: Bool) {
        isScanning = enabled
        self.localData?.setScanState(isScanning: isScanning)
        if isScanning {
            Bugsnag.leaveBreadcrumb(withMessage: "Lidar Occlusions: started scan")
            scanButton.setTitle("Stop Scanning", for: .normal)
        } else {
            Bugsnag.leaveBreadcrumb(withMessage: "Lidar Occlusions: stopped scan")
            scanButton.setTitle("Start Scanning", for: .normal)
            didSucceed = true
        }
    }
    
    func setDataModel(data: LocalData) {
        localData = data
//        configureLocalData()
    }
    
    private func openView() {
        subviewTopConstraint.constant = 0
        
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    private func closeView() {
        subviewTopConstraint.constant = -subview.frame.height
        
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: .curveEaseInOut) { [weak self] in
            self?.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            guard let self = self else { return }
            if self.didSucceed {
                self.trackEvent(name: "lidar occlusion success", parameters: nil)
            }
            self.delegate?.closeView(self)
        }
    }
}

private typealias Configuration = LidarOcclusionWizardViewController
extension Configuration {
//    private func configureLocalData() {
//        localData?.$threshold
//            .receive(on: RunLoop.main)
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//
//                self.refreshTimer?.invalidate()
//                self.refreshTimer = Timer.scheduledTimer(timeInterval: 0.2,
//                                                         target: self,
//                                                         selector: #selector(self.updateView),
//                                                         userInfo: nil,
//                                                         repeats: false)
//            }
//            .store(in: &cancellables)
//    }
    
//    @objc func updateView() {
//        guard let threshold = localData?.threshold
//        else { return }
//
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            let animated = self.lastRefreshState != data.state
//            self.lastRefreshState = data.state
//            self.pagerView?.scrollToItem(at: data.state.rawValue, animated: animated)
//            self.didFinishLoading = true
//        }
//    }

    private func applyUICustomization() {
        guard let customizationRepo = customizationRepo
        else { return }

        let uiOptions = customizationRepo.options.uiOptions
        let textColor = uiOptions.colors.text.color
        let close = uiOptions.buttonIcons.shaderOcclusionCloseIcon
        closeButton.imageView?.setImage(with: close, placeholder: nil)
        
        titleLabel.font = uiOptions.font.font(with: 16)
        titleLabel.textColor = textColor
    }
}
