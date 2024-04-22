//
//  HomeCoordinator.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/28/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

protocol HomeCoordinatorDelegate: AnyObject {
    func showChangeStore()
}

class HomeCoordinator: Coordinator<Void> {
    weak var delegate: HomeCoordinatorDelegate?
    
    var homeViewController = HomeViewController.instantiate(fromStoryboardNamed: .Home)
    
    override func toPresentable() -> UIViewController {
        homeViewController
    }

    override func start() {
        homeViewController = HomeViewController.instantiate(fromStoryboardNamed: .Home)
        homeViewController.delegate = self
        homeViewController.customizationRepo = dependencies.customizationRepo
        router.setRootModule(toPresentable(), hideBar: true)
    }
}

extension HomeCoordinator: HomeViewControllerDelegate {
    func showChangeStore(_ controller: HomeViewController) {
        delegate?.showChangeStore()
    }

    func showMethod(_ controller: HomeViewController, method: ARMethod) {
        var coordinator: Coordinator<Void>?
        
        switch method.type {
        case .roomplan:
            if #available(iOS 16, *) {
                coordinator = RoomPlanCoordinator(router: router,
                                                  dependencies: dependencies)
            }
            
        case .lidar:
            coordinator = LidarCoordinator(router: router,
                                           dependencies: dependencies)
            
        case .floorplan:
            coordinator = FloorplanCoordinator(router: router,
                                               dependencies: dependencies)
            
        case .swatch:
            coordinator = LegacyCoordinator(router: router,
                                            dependencies: dependencies)
            
        case .shader:
            coordinator = ShaderPaintCoordinator(router: router,
                                                 dependencies: dependencies)
        
        case .mlsdk:
            coordinator = MLCoordinator(router: router,
                                        dependencies: dependencies)
        }
        
        guard let coordinator = coordinator
        else { return }

        addChild(coordinator)
        coordinator.start()

        router.push(coordinator, animated: true) { [weak self, weak coordinator] in
            self?.removeChild(coordinator)
        }
    }
    
    func showMethodInfo(_ controller: HomeViewController, methodInfo: ARMethodInfo) {
        let methodInfoView = ARInfoViewController.instantiate(fromStoryboardNamed: .Home)
        methodInfoView.methodInfo = methodInfo
        methodInfoView.delegate = self
        methodInfoView.customizationRepo = dependencies.customizationRepo
        router.push(methodInfoView, animated: true, completion: nil)
    }
}

extension HomeCoordinator: ARInfoViewControllerDelegate {
    func dismiss(_ controller: ARInfoViewController) {
        router.popModule(animated: true)
    }
}
