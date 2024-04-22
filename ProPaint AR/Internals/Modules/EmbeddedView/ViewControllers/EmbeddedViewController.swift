//
//  EmbeddedViewController.swift
//  Coordinator-Barebones
//
//  Created by Davido Hyer on 5/4/22.
//

import Combine
import UIKit

protocol EmbeddedViewControllerDelegate: AnyObject {
    func closeView(_ result: String?, controller: EmbeddedViewController)
}

class EmbeddedViewController: UIViewController {
    // Note: The main view is defined as a PassthroughView. This enables touches to be passed through to the view underneath this one. To disable this, just change the view class back to UIView.
    
    @IBOutlet weak var subviewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var subview: UIView!
    @IBOutlet weak var optionsSegment: UISegmentedControl!
    weak var delegate: EmbeddedViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subviewTopConstraint.constant = -subview.frame.height
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        openView()
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        let value = optionsSegment.titleForSegment(at: optionsSegment.selectedSegmentIndex)
        
        closeView(value: value)
    }
    
    func openView() {
        subviewTopConstraint.constant = 0
        
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    func closeView(value: String?) {
        subviewTopConstraint.constant = -subview.frame.height
        
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: .curveEaseInOut) { [weak self] in
            self?.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.closeView(value, controller: self)
        }
    }
}
