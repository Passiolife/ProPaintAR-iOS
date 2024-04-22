//
//  StoreCoordinator.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 25/07/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

protocol StoreCoordinatorDelegate: AnyObject {
    func showDemo()
    func showStore(storeId: String)
}

class StoreCoordinator: Coordinator<Void> {
    weak var delegate: StoreCoordinatorDelegate?
    
    private lazy var viewController: StoreViewController = {
        let controller = StoreViewController.instantiate(fromStoryboardNamed: .Store)
        controller.delegate = self
        return controller
    }()

    override func toPresentable() -> UIViewController {
        viewController
    }
    
    override func start() {
        router.setRootModule(toPresentable(), hideBar: true)
    }
    
    func showLoadingIndicator(storeId: String) {
        viewController.loadStore(storeId: storeId)
        viewController.loadingView?.isHidden = false
    }
    
    func updateProgress(progress: Float) {
        viewController.updateProgress(progress: progress)
    }
}

extension StoreCoordinator: StoreViewControllerDelegate {
    func showDemoApp(_ controller: StoreViewController) {
        delegate?.showDemo()
    }

    func showDashboard(_ controller: StoreViewController, storeId: String) {
        delegate?.showStore(storeId: storeId)
    }
}
