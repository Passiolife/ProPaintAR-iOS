//
//  UIViewController+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/5/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

public extension UIViewController {
    func reloadViewFromNib() {
        let parent = view.superview
        view.removeFromSuperview()
        view = nil
        parent?.addSubview(view)
    }
    
    func present<T>(_ coordinator: Coordinator<T>, animated: Bool = true) {
        present(coordinator.router.navigationController, animated: animated, completion: nil)
    }

    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    func remove() {
        // Just to be safe, we check that this view controller
        // is actually added to a parent before removing it.
        guard parent != nil else {
            return
        }

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
    /// Embeds a UIViewController inside of another UIViewController using its view.
    /// - Parameters:
    ///   - Parameter viewController: UIViewController to embed
    ///   - Parameter frame:  A frame to be used. Nil by default and used view's frame.
    func embed(viewController: UIViewController, frame: CGRect? = nil) {
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.didMove(toParent: self)
    }
    
    /// Removes an embedded UIViewController from a UIVIewController
    /// - Parameters:
    ///   - Parameter embeddedViewController: UIViewController to remove
    func remove(embeddedViewController: UIViewController) {
        guard children.contains(embeddedViewController) else {
            return
        }
        
        embeddedViewController.willMove(toParent: nil)
        embeddedViewController.view.removeFromSuperview()
        embeddedViewController.removeFromParent()
    }
    
    func showMessage(
        title: String?,
        message: String?,
        cancelTitle: String?,
        cancelStyle: UIAlertAction.Style = .default,
        style: UIAlertController.Style = .actionSheet,
        sourceView: UIView? = nil,
        okTitle: String?,
        okStyle: UIAlertAction.Style = .default,
        okAction: ((UIAlertAction) -> Void)?
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let okAction = UIAlertAction(title: okTitle, style: okStyle, handler: okAction)
        let cancelAction = UIAlertAction(title: cancelTitle, style: cancelStyle, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        if let presenter = alert.popoverPresentationController,
           let sourceView = sourceView {
            presenter.sourceView = sourceView
            presenter.sourceRect = sourceView.bounds
            presenter.permittedArrowDirections = [.down]
        }
        
        present(alert, animated: true)
    }
    
    func showMessage(
        title: String?,
        message: String?,
        okTitle: String?,
        style: UIAlertController.Style = .actionSheet,
        sourceView: UIView? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let okAction = UIAlertAction(title: okTitle, style: .default, handler: nil)
        alert.addAction(okAction)
        
        if let presenter = alert.popoverPresentationController,
           let sourceView = sourceView {
            presenter.sourceView = sourceView
            presenter.sourceRect = sourceView.bounds
            presenter.permittedArrowDirections = [.down]
        }
        
        present(alert, animated: true)
    }
    
    static var identifier: String {
        String(describing: self)
    }
}
