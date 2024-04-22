//
//  HomeViewController.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/28/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import ARKit
import Bugsnag
import UIKit

protocol HomeViewControllerDelegate: AnyObject {
    func showMethod(_ controller: HomeViewController, method: ARMethod)
    func showMethodInfo(_ controller: HomeViewController, methodInfo: ARMethodInfo)
    func showChangeStore(_ controller: HomeViewController)
}

class HomeViewController: UIViewController, Trackable {
    var delegate: HomeViewControllerDelegate?
    var customizationRepo: CustomizationRepo?
    
    @IBOutlet weak var pagerView: FSPagerView! {
        didSet {
            self.pagerView.register(
                UINib(nibName: "MethodCell", bundle: Bundle.main),
                forCellWithReuseIdentifier: "MethodCell"
            )
        }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var changeStoreButton: RoundedButton!
    @IBOutlet weak var frameView: UIView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var backgroundOverlay: UIView?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Bugsnag.leaveBreadcrumb(withMessage: "Home: Started")
        trackScreen(name: "home")
        updateViews()
        navigationController?.isNavigationBarHidden = true
    }
    
    private func updateViews() {
        frameView.layer.cornerRadius = 10
        frameView.layer.masksToBounds = true
        pagerView.itemSize = CGSize(width: 366, height: 302)
        pageControl.numberOfPages = ARMethod.data.count
        applyUICustomization()
    }
    
    func applyUICustomization() {
        guard let customiseOptions = customizationRepo
        else { return }
        
        let uiOptions = customiseOptions.options.uiOptions
        let buttonColor = uiOptions.colors.button.color
        let buttonTextColor = uiOptions.colors.buttonText.color
        let textColor = uiOptions.colors.text.color
        let backgroundResource = uiOptions.backgroundImage
        let backgroundImageOverlay = uiOptions.colors.backgroundImageOverlay.color
        let frameBackgroundColor = uiOptions.colors.frameBackground.color
        let highlightedColor = uiOptions.colors.highlighted.color
        let unhighlightedColor = uiOptions.colors.unhighlighted.color
        backgroundImage.setImage(with: backgroundResource, placeholder: nil)
        backgroundImage.alpha = 1
        
        titleLabel.font = uiOptions.font.font(with: 17)
        titleLabel.textColor = textColor
        
        changeStoreButton.titleLabel?.font = uiOptions.font.font(with: 14)
        changeStoreButton.setTitleColor(buttonTextColor, for: .normal)
        changeStoreButton.backgroundColor = buttonColor
        
        frameView.backgroundColor = frameBackgroundColor
        pageControl.currentPageIndicatorTintColor = highlightedColor
        pageControl.pageIndicatorTintColor = unhighlightedColor
        
        backgroundOverlay?.backgroundColor = backgroundImageOverlay
    }
    
    @IBAction func onChangeStoreTapped(_ sender: UIButton) {
        Bugsnag.leaveBreadcrumb(withMessage: "Home: change store")
        delegate?.showChangeStore(self)
    }
    
    @IBAction func pageControlChanged(_ sender: Any) {
        pagerView.scrollToItem(at: pageControl.currentPage, animated: false)
    }
    
    @IBAction func moreInfoTapped(_ sender: Any) {
        guard let url = URL(string: "https://www.passio.ai/paints-ai")
        else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

extension HomeViewController: FSPagerViewDataSource {
    public func numberOfItems(in pagerView: FSPagerView) -> Int {
        ARMethod.data.count
    }
    
    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "MethodCell", at: index)
        if let cell = cell as? MethodCell,
           index < ARMethod.data.count {
            let method = ARMethod.data[index]
            cell.configure(index: index,
                           method: method,
                           customizationRepo: customizationRepo)
            cell.continueCallback = { [weak self] sender in
                guard let self = self else { return }
                
                let method = ARMethod.data[pagerView.currentIndex]
                
                if case .lidar = method.type,
                   !ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                    let message = "This device doesn't support Lidar. Please try a different method."
                    self.showMessage(title: "Lidar Not Supported",
                                     message: message,
                                     okTitle: "ok",
                                     style: .actionSheet,
                                     sourceView: sender)
                    return
                }
                
                self.delegate?.showMethod(self, method: method)
            }
            cell.infoCallback = { [weak self] _ in
                guard let self = self else { return }
                
                let method = ARMethod.data[self.pagerView.currentIndex]
                self.delegate?.showMethodInfo(self, methodInfo: method.info)
            }
        }
        
        return cell
    }
}

extension HomeViewController: FSPagerViewDelegate {
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }
}
