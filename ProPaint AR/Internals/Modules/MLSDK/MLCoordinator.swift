//
//  MLCoordinator.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/2/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

class MLCoordinator: Coordinator<Void> {
    private lazy var viewController: MLViewController = {
        let controller = MLViewController.instantiate(fromStoryboardNamed: .MLMethods)
        controller.delegate = self
        controller.customizationRepo = dependencies.customizationRepo
        return controller
    }()
    
    override func toPresentable() -> UIViewController {
        viewController
    }
}

extension MLCoordinator: MLViewControllerDelegate {
    func dismiss(_ controller: MLViewController) {
        router.popModule(animated: true)
    }
    
    func methodSelected(method: MLMethod, controller: MLViewController) {
        let methodView = MLMethodViewController.instantiate(model: method.modelType,
                                                            customizationRepo: dependencies.customizationRepo,
                                                            delegate: self)
        router.push(methodView, animated: true, completion: nil)
    }
}

extension MLCoordinator: MLMethodViewControllerDelegate {
    func dismiss(_ controller: MLMethodViewController) {
        router.popModule(animated: true)
    }
}
