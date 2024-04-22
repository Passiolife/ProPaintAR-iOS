//
//  CartCoordinator.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 7/4/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import RemodelAR
import UIKit

class CartCoordinator: Coordinator<Void> {
    private lazy var viewController: CartViewController = {
        let controller = CartViewController.instantiate(
            cartRepo: dependencies.cartRepo,
            customizationRepo: dependencies.customizationRepo
        )
        controller.delegate = self
        return controller
    }()
    
    init(
        paintInfo: PaintInfo,
        router: Router,
        dependencies: AppDependency,
        presenter: UIViewController? = nil
    ) {
        dependencies.cartRepo.addItems(from: paintInfo,
                                       colorRepo: dependencies.colorRepo)
        super.init(router: router,
                   dependencies: dependencies,
                   presenter: presenter)
    }
    
    override func toPresentable() -> UIViewController {
        viewController
    }
}

extension CartCoordinator: CartViewControllerDelegate {
    func dismiss(_ controller: CartViewController) {
        router.popModule(animated: false)
        finish(())
    }
}
