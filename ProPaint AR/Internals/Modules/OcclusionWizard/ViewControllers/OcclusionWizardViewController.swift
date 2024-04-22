//
//  OcclusionWizardViewController.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/3/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Bugsnag
import Combine
import UIKit

protocol OcclusionWizardViewControllerDelegate: AnyObject {
    func closeView(_ controller: OcclusionWizardViewController)
}

class OcclusionWizardViewController: UIViewController, Trackable {
    @IBOutlet weak var subviewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var subview: UIView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var pagerView: FSPagerView? {
        didSet {
            self.pagerView?.register(UINib(nibName: "OcclusionWizardStartCell",
                                           bundle: Bundle.main),
                                     forCellWithReuseIdentifier: "OcclusionWizardStartCell")
            self.pagerView?.register(UINib(nibName: "OcclusionWizardAddColorsCell",
                                           bundle: Bundle.main),
                                     forCellWithReuseIdentifier: "OcclusionWizardAddColorsCell")
            self.pagerView?.register(UINib(nibName: "OcclusionWizardThresholdCell",
                                           bundle: Bundle.main),
                                     forCellWithReuseIdentifier: "OcclusionWizardThresholdCell")
        }
    }
    
    private var didFinishLoading = false
    private var didSucceed = false
    private var refreshTimer: Timer?
    private var lastRefreshState: OcclusionState = .start
    private var thresholdAnalyticsTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private weak var localData: LocalData?
    weak var delegate: OcclusionWizardViewControllerDelegate?
    var customizationRepo: CustomizationRepo?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        subviewTopConstraint.constant = -subview.frame.height
        configureLocalData()
        applyUICustomization()
        Bugsnag.leaveBreadcrumb(withMessage: "Occlusions: Started")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        trackScreen(name: "occlusion wizard")
        openView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        trackEvent(name: "occlusion wizard closed", parameters: nil)
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Occlusions: closed")
        closeView()
    }
    
    func setDataModel(data: LocalData) {
        localData = data
        configureLocalData()
    }
    
    func addColor(color: UIColor) {
        addColorsCell.addedColor(color: color)
    }
    
    private func startCell() -> OcclusionWizardStartCell {
        let cell = pagerView?.dequeueReusableCell(withReuseIdentifier: "OcclusionWizardStartCell",
                                                  // swiftlint:disable:next force_cast
                                                  at: 0) as! OcclusionWizardStartCell
        cell.configure(with: customizationRepo)
        cell.delegate = self
        return cell
    }
    
    private lazy var addColorsCell: OcclusionWizardAddColorsCell = {
        let cell = pagerView?.dequeueReusableCell(withReuseIdentifier: "OcclusionWizardAddColorsCell",
                                                  // swiftlint:disable:next force_cast
                                                  at: 0) as! OcclusionWizardAddColorsCell
        cell.configure(with: localData?.colors ?? [])
        cell.configure(with: customizationRepo)
        cell.delegate = self
        return cell
    }()
    
    private func thresholdCell() -> OcclusionWizardThresholdCell {
        let cell = pagerView?.dequeueReusableCell(withReuseIdentifier: "OcclusionWizardThresholdCell",
                                                  // swiftlint:disable:next force_cast
                                                  at: 0) as! OcclusionWizardThresholdCell
        cell.configure(with: localData?.threshold ?? 0)
        cell.configure(with: customizationRepo)
        cell.delegate = self
        return cell
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
                self.trackEvent(name: "occlusion success", parameters: nil)
            }
            self.delegate?.closeView(self)
        }
    }
}

extension OcclusionWizardViewController: FSPagerViewDataSource {
    public func numberOfItems(in pagerView: FSPagerView) -> Int {
        3
    }
        
    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cellType = OcclusionCellType(rawValue: index)
        switch cellType {
        case .startCell:
            return startCell()
            
        case .addColorsCell:
            return addColorsCell
            
        case .thresholdCell:
            return thresholdCell()
        }
    }
}

extension OcclusionWizardViewController: OcclusionWizardStartCellDelegate {
    func getStartedTapped(_ sender: OcclusionWizardStartCell) {
        trackEvent(name: "occlusion wizard get started", parameters: nil)
        localData?.setOcclusionState(state: .pickingColors)
    }
}

extension OcclusionWizardViewController: OcclusionWizardAddColorsCellDelegate {
    func continueTapped(_ sender: OcclusionWizardAddColorsCell) {
        localData?.setOcclusionState(state: .adjustingThreshold)
    }
    
    func colorsUpdated(colors: [UIColor], sender: OcclusionWizardAddColorsCell) {
        let colorsString = colors.map({ $0.toHexString() }).joined(separator: ", ")
        trackEvent(name: "occlusion wizard color added",
                   parameters: ["colors": colorsString])
        localData?.colors = colors
    }
}

extension OcclusionWizardViewController: OcclusionWizardThresholdCellDelegate {
    func thresholdUpdated(threshold: Float, sender: OcclusionWizardThresholdCell) {
        guard let localData = localData
        else { return }
        
        didSucceed = true
        thresholdAnalyticsTimer?.invalidate()
        thresholdAnalyticsTimer = Timer.scheduledTimer(withTimeInterval: 0.25,
                                                       repeats: false,
                                                       block: { [weak self] _ in
            self?.trackEvent(name: "occlusion wizard threshold updated",
                             parameters: ["threshold": threshold])
        })
        
        localData.threshold = threshold
    }
    
    func adjustColors(_ sender: OcclusionWizardThresholdCell) {
        localData?.state = .pickingColors
    }
    
    func resetOcclusion(_ sender: OcclusionWizardThresholdCell) {
        trackEvent(name: "occlusion wizard reset", parameters: nil)
        localData?.reset()
        addColorsCell.reset()
        thresholdCell().configure(with: localData?.threshold ?? 0)
    }
}

private typealias Configuration = OcclusionWizardViewController
extension Configuration {
    private func configureLocalData() {
        localData?.$data
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.refreshTimer?.invalidate()
                self.refreshTimer = Timer.scheduledTimer(timeInterval: 0.2,
                                                         target: self,
                                                         selector: #selector(self.updateView),
                                                         userInfo: nil,
                                                         repeats: false)
            }
            .store(in: &cancellables)
    }
    
    @objc func updateView() {
        guard let data = localData?.data
        else { return }
        
        pagerView?.reloadData()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let animated = self.lastRefreshState != data.state
            self.lastRefreshState = data.state
            self.pagerView?.scrollToItem(at: data.state.rawValue, animated: animated)
            self.didFinishLoading = true
        }
    }

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
